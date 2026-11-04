# Source-faithful staging and expression evaluation. Definitions only.
split_field <- function(x) if(is.na(x) || !nzchar(x)) character() else strsplit(x,";",fixed=TRUE)[[1]]
figure_catalog <- function(root) read.csv(file.path(root,"configs/figures/targets.csv"),
                                         stringsAsFactors=FALSE,na.strings="")
simulation_file <- function(name) paste0("simulate_sirs_",tolower(name),".rda")
fit_object_name <- function(variant,region) paste0("stanfit_sirs_",tolower(region),
                                                  if(variant=="seasonal") "_npi" else "_npi2")
phase4_fit <- function(fits,variant,region,o,registry,src,bundle_path) {
  if(is.null(fits)) stop("Missing --fits for ",variant,"/",region)
  parent <- file.path(fits,variant,region)
  attempts <- list.dirs(parent,recursive=FALSE,full.names=TRUE)
  completed <- attempts[file.exists(file.path(attempts,"COMPLETE"))]
  if(length(completed)!=1L) stop("Expected exactly one completed attempt at ",parent,
    "; found ",length(completed),". Use a separate unambiguous campaign root.")
  path <- normalizePath(completed)
  manifest <- readRDS(file.path(path,"manifest.rds"))
  cfg <- registry[registry$region==region & registry$variant==variant,,drop=FALSE]
  if(nrow(cfg)!=1L || manifest$commit!=source_commit || !identical(manifest$config,cfg))
    stop("Source/configuration mismatch: ",path)
  s <- manifest$settings
  # Never accept the Phase 2 smoke configuration, including in non-reproduction mode.
  if(s$chains<4L || s$iter-s$warmup<2000L || s$warmup<2000L)
    stop("Full posterior required; smoke/short chains rejected: ",path)
  allow_nonrep <- identical(o$mode,"non-reproduction")
  expected <- settings(list(),cfg)
  if(!allow_nonrep && !identical(s,expected)) stop("Non-original inference settings: ",path,
    "; explicit --mode non-reproduction required for a labelled comparison")
  if(manifest$model_sha256!=hash_file(file.path(src,"stanmodel",paste0(cfg$model,".stan"))) ||
     manifest$data_sha256!=hash_file(file.path(bundle_path,"bundle.rds")))
    stop("Model/data digest mismatch: ",path)
  data <- readRDS(file.path(path,"standata.rds"))
  bundle <- readRDS(file.path(bundle_path,"bundle.rds"))
  if(!identical(data,bundle$data[[paste(variant,region,sep="/")]])) stop("Stan input mismatch: ",path)
  obj <- fit_object_name(variant,region)
  needed <- c("fit.rds",paste0(obj,".rda"),"manifest.rds","standata.rds","model.stan")
  if(!all(file.exists(file.path(path,needed)))) stop("Missing posterior artifacts: ",path)
  list(path=path,object=obj,manifest=manifest,
       rda=file.path(path,paste0(obj,".rda")),
       diagnostic_status=if(file.exists(file.path(path,"diagnostics/quality_checks.txt")))
         readLines(file.path(path,"diagnostics/quality_checks.txt")) else "NOT_CHECKED")
}
stage_original <- function(out,root,src,bundle_path,fit_dependencies) {
  stage <- file.path(out,"workspace"); dir.create(stage)
  # Copy code and inputs only: do not copy author PDF/PNG reference artifacts.
  files <- list.files(src,recursive=TRUE,full.names=FALSE,all.files=FALSE)
  files <- files[grepl("[.](R|stan|csv|xlsx)$",files)]
  for(f in files) {
    to <- file.path(stage,f); dir.create(dirname(to),recursive=TRUE,showWarnings=FALSE)
    stopifnot(file.copy(file.path(src,f),to,overwrite=FALSE))
  }
  for(d in c("stanfit_sirs","stanfit_sirs2","simulate_sirs","figure","analysis","R"))
    dir.create(file.path(stage,d),showWarnings=FALSE)
  # Same compatibility helper introduced in Phase 2, with a checked source hash.
  helper <- file.path(root,"work",source_commit,"R/firstup.R")
  recorded <- read.delim(file.path(root,"patches/file_hashes.tsv"),check.names=FALSE)
  stopifnot(hash_file(helper)==recorded$execution_copy_sha256[recorded$path=="R/firstup.R"])
  stopifnot(file.copy(helper,file.path(stage,"R/firstup.R")))
  bundle <- readRDS(file.path(bundle_path,"bundle.rds"))
  stopifnot(bundle$commit==source_commit)
  original_paths <- c("cases.csv"="data/japan_rsv.csv","population.csv"="data/japan_pop.csv",
                     "humidity.csv"="data_processed/data_processed_humidity.csv",
                     "temperature.csv"="data_processed/data_processed_temperature.csv")
  for(n in names(original_paths)) stopifnot(bundle$inputs[[n]]==hash_file(file.path(stage,original_paths[[n]])))
  for(dep in fit_dependencies) {
    variant <- dep$manifest$config$variant
    dir <- if(variant=="seasonal") "stanfit_sirs" else "stanfit_sirs2"
    stopifnot(file.copy(dep$rda,file.path(stage,dir,basename(dep$rda)),overwrite=FALSE))
  }
  stage
}
original_environment <- function(record_simulator=FALSE) {
  env <- new.env(parent=globalenv())
  tape <- new.env(parent=emptyenv()); tape$calls <- list()
  env$source <- function(file,local=env,...) {
    # Keep source() assignments inside this isolated script environment.
    base::sys.source(file,envir=local)
    if(record_simulator && basename(file)=="simulate_sirs.R") {
      original <- local$simulate_sirs
      local$simulate_sirs <- function(...) {
        args <- list(...); states <- original(...)
        tape$calls[[length(tape$calls)+1L]] <- list(arguments=args,states=states)
        states
      }
    }
    invisible(NULL)
  }
  env$load <- function(file,envir=env,...) {
    loaded <- base::load(file,envir=envir,...)
    for(n in loaded) if(inherits(envir[[n]],"stanfit")) {
      f <- envir[[n]]
      stopifnot(f@mode==0L,f@sim$chains>=4L,f@sim$iter-f@sim$warmup>=2000L,
                f@sim$warmup>=2000L,f@sim$thin==1L)
    }
    invisible(loaded)
  }
  list(env=env,tape=tape)
}
evaluate_original <- function(file,env) {
  old <- getwd(); on.exit(setwd(old),add=TRUE); setwd(dirname(file))
  parsed <- parse(basename(file),keep.source=TRUE)
  visible <- list()
  for(i in seq_along(parsed)) {
    result <- withVisible(eval(parsed[[i]],envir=env))
    if(result$visible && !is.function(result$value)) {
      print(result$value)
      visible[[length(visible)+1L]] <- list(expression=paste(deparse(parsed[[i]]),collapse="\n"),
                                         value=result$value)
    }
  }
  invisible(visible)
}
export_figure_objects <- function(env,out) {
  dir.create(file.path(out,"tables")); dir.create(file.path(out,"panels"))
  wanted <- c("japan_rsv_summ","japan_rsv_prefecture2","japan_rsv_island","fitdata",
    "fitdata_filter","npidata","Sdata","Sdata_summ","betadata","beta2data","betadata2",
    "betadata_t2","betadata_comb","childcare","childcare2","allsim","allsim_summ",
    "allsim_filter","simulate_sirs_interpolate","japan_humidity_island2","japan_temperature_island2")
  for(n in wanted) if(exists(n,envir=env,inherits=FALSE) && is.data.frame(env[[n]]))
    write.csv(as.data.frame(env[[n]]),file.path(out,"tables",paste0(n,".csv")),row.names=FALSE)
  for(n in ls(env,pattern="^g[0-9]+[a-z]?$")) if(inherits(env[[n]],"ggplot"))
    atomic_rds(env[[n]],file.path(out,"panels",paste0(n,".rds")))
  # Record both actual GAM prediction grids, without recomputing or resmoothing.
  grid <- c("week_gam","week_gam_pred","beta_smooth_honshu","beta_smooth_kyushu",
            "seas_smooth_honshu","seas_smooth_kyushu","amp_honshu","amp_kyushu")
  values <- mget(intersect(grid,ls(env)),envir=env,inherits=FALSE)
  if(length(values)) atomic_rds(values,file.path(out,"smoothing_values.rds"))
}

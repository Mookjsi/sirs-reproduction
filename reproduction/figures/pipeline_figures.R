# Phase 4 dispatch and dependency inspection; functions are not executed when sourced.
with_figure_log <- function(out,fun) {
  previous_message_connection <- sink.number(type="message")
  on.exit({
    if(previous_message_connection!=2L)
      sink(getConnection(previous_message_connection),type="message")
  },add=TRUE)
  with_stage(out,fun)
}
target_rows <- function(o,root) {
  cat <- figure_catalog(root)
  id <- if(!is.null(o$target)) o$target else if(!is.null(o$figure)) paste0("figure",o$figure) else "all"
  if(id=="all") {
    if(o$command=="supplement") return(cat[grepl("^s",cat$target),,drop=FALSE])
    if(o$command=="figure") return(cat[grepl("^figure",cat$target),,drop=FALSE])
    return(cat)
  }
  rows <- cat[cat$target==id,,drop=FALSE]
  if(!nrow(rows)) stop("Unknown figure target: ",id)
  rows
}
phase4_dependencies <- function(o,root,src,registry) {
  deps <- list(); failures <- character()
  bundle_path <- if(is.null(o$data)) "" else path.expand(o$data)
  b <- tryCatch({
    x <- readRDS(file.path(bundle_path,"bundle.rds"))
    stopifnot(x$commit==source_commit,identical(x$registry,registry))
    x
  },error=function(e) {failures <<- c(failures,paste("Prepared data:",conditionMessage(e)));NULL})
  counterfactual <- o$command=="counterfactual"
  if(counterfactual) {
    names <- simulation_selection(need(o,"experiment"))
    rows <- data.frame(target=paste0("counterfactual-",o$experiment),script="",
      variant="seasonal",regions=paste(simulation_regions(names),collapse=";"),
      simulations="",packages=paste(c("tidyr","dplyr","rstan",
        if("interpolate" %in% names) "mgcv"),collapse=";"),outputs="")
  } else rows <- target_rows(o,root)
  installed <- rownames(installed.packages())
  source_manifest <- read.delim(file.path(root,"audit_artifacts/source_manifest.tsv"))
  report <- lapply(seq_len(nrow(rows)),function(i) {
    r <- rows[i,]; problems <- failures
    originals <- c("script/script_data.R","data/japan_rsv.csv","data/japan_pop.csv",
      "data_processed/data_processed_humidity.csv","data_processed/data_processed_temperature.csv")
    if(nzchar(r$script)) originals <- c(originals,r$script)
    if(r$target=="figure4") originals <- c(originals,"data/japan_childcare.xlsx")
    if(counterfactual) originals <- c(originals,"R/simulate_sirs.R",
      paste0("simulate_sirs/simulate_sirs_",tolower(names),".R"))
    for(f in originals) {
      path <- file.path(src,f)
      expected <- source_manifest$sha256[source_manifest$relative_path==f]
      if(!file.exists(path) || length(expected)!=1L || hash_file(path)!=expected)
        problems <- c(problems,paste("Missing or changed pinned source/input",f))
    }
    helper <- file.path(root,"work",source_commit,"R/firstup.R")
    if(!file.exists(helper)) problems <- c(problems,"Missing Phase 2 capitalization helper R/firstup.R")
    for(pkg in split_field(r$packages)) if(!pkg %in% installed)
      problems <- c(problems,paste("Missing R package",pkg))
    if(nzchar(r$script) && !file.exists(file.path(src,r$script)))
      problems <- c(problems,paste("Missing original script",r$script))
    if(r$target=="figure4" && !file.exists(file.path(src,"data/japan_childcare.xlsx")))
      problems <- c(problems,"Childcare workbook absent: data/japan_childcare.xlsx; panels A/B BLOCKED")
    for(region in split_field(r$regions)) {
      key <- paste(r$variant,region,sep="/")
      dep <- tryCatch(phase4_fit(o$fits,r$variant,region,o,registry,src,bundle_path),error=function(e) e)
      if(inherits(dep,"error")) problems <- c(problems,conditionMessage(dep)) else deps[[key]] <<- dep
    }
    sims <- split_field(r$simulations)
    if(length(sims)) {
      if(is.null(o$simulations) || !file.exists(file.path(o$simulations,"SIMULATIONS_COMPLETE"))) {
        problems <- c(problems,paste("Completed --simulations required:",paste(sims,collapse=",")))
      } else {
        prov <- tryCatch(readRDS(file.path(o$simulations,"figure_provenance.rds")),error=function(e) NULL)
        if(is.null(prov) || is.null(b) || length(prov$data_sha256)!=1L ||
           prov$data_sha256!=hash_file(file.path(bundle_path,"bundle.rds")))
          problems <- c(problems,"Simulation data provenance mismatch")
        for(n in sims) {
          f <- file.path(o$simulations,"workspace/simulate_sirs",simulation_file(n))
          if(!file.exists(f)) problems <- c(problems,paste("Missing simulation",n))
        }
        hashes <- tryCatch(read.csv(file.path(o$simulations,"simulation_hashes.csv")),
                           error=function(e) NULL)
        for(n in sims) {
          f <- file.path(o$simulations,"workspace/simulate_sirs",simulation_file(n))
          if(is.null(hashes) || sum(hashes$name==n)!=1L || !file.exists(f) ||
             hash_file(f)!=hashes$sha256[hashes$name==n])
            problems <- c(problems,paste("Simulation artifact hash unavailable/mismatched",n))
        }
        if(!is.null(prov)) for(region in simulation_regions(sims)) {
          key <- paste("seasonal",region,sep="/"); dep <- deps[[key]]
          if(!is.null(dep) && (!key %in% names(prov$fit_hashes) ||
             prov$fit_hashes[[key]]!=hash_file(dep$rda)))
            problems <- c(problems,paste("Simulation/posterior mismatch",key))
        }
      }
    }
    data.frame(target=r$target,status=if(length(problems)) "BLOCKED" else "READY",
               detail=if(length(problems)) paste(unique(problems),collapse=" | ") else
                 "Dependencies available; convergence and numerical reproduction not certified")
  })
  list(rows=rows,report=do.call(rbind,report),fits=deps,bundle=b)
}
phase4_provenance <- function(out,o,root,src,deps) {
  fit_hashes <- vapply(deps$fits,function(d) hash_file(d$rda),character(1))
  provenance <- list(commit=source_commit,data_sha256=hash_file(file.path(o$data,"bundle.rds")),
    mode=if(is.null(o$mode)) "reproduction" else o$mode,fit_hashes=fit_hashes,
    manifests=lapply(deps$fits,`[[`,"manifest"),
    diagnostics=lapply(deps$fits,`[[`,"diagnostic_status"),
    targets=deps$rows,upstream_source_manifest=read.delim(file.path(root,"audit_artifacts/source_manifest.tsv")),
    figure_config_sha256=hash_file(file.path(root,"configs/figures/targets.csv")),
    counterfactual_config_sha256=hash_file(file.path(root,"configs/figures/counterfactuals.R")))
  atomic_rds(provenance,file.path(out,"figure_provenance.rds"))
  capture.output(dput(provenance),file=file.path(out,"figure_provenance.txt"))
  files <- c("figures/source_adapter.R","figures/pipeline_figures.R",
             "simulations/original_counterfactuals.R","configs/figures/targets.csv",
             "configs/figures/counterfactuals.R")
  write.csv(data.frame(file=files,sha256=vapply(file.path(root,files),hash_file,character(1))),
            file.path(out,"phase4_code_hashes.csv"),row.names=FALSE)
}
execute_figures <- function(o,root,src,deps,out) {
  for(i in seq_len(nrow(deps$rows))) {
    r <- deps$rows[i,]
    if(deps$report$status[i]!="READY") next
    destination <- fresh_directory(file.path(out,r$target))
    required <- lapply(split_field(r$regions),function(region) deps$fits[[paste(r$variant,region,sep="/")]])
    stage <- stage_original(destination,root,src,o$data,required)
    for(n in split_field(r$simulations)) stopifnot(file.copy(
      file.path(o$simulations,"workspace/simulate_sirs",simulation_file(n)),
      file.path(stage,"simulate_sirs",simulation_file(n)),overwrite=FALSE))
    env <- original_environment()$env
    with_figure_log(destination,function() {
      # The original map script sets its theme before attaching ggplot2; preload only.
      library(ggplot2)
      visible <- evaluate_original(file.path(stage,r$script),env)
      export_figure_objects(env,destination)
      atomic_rds(visible,file.path(destination,"visible_results.rds"))
      expected <- split_field(r$outputs)
      if(length(expected)) stopifnot(all(file.exists(file.path(stage,"figure",expected))))
      products <- list.files(file.path(stage,"figure"),pattern="[.](pdf|png)$",full.names=TRUE)
      if(length(products)) {
        dir.create(file.path(destination,"products"))
        stopifnot(all(file.copy(products,file.path(destination,"products"),overwrite=FALSE)))
      }
      writeLines("Generated by original script; comparison pending user verification.",
                 file.path(destination,"COMPARISON_PENDING"))
    })
    rm(env); gc(verbose=FALSE)
  }
}
phase4_dispatch <- function(o,root,src,registry) {
  if(!is.null(o$mode) && !o$mode %in% c("reproduction","non-reproduction")) stop("Invalid --mode")
  deps <- phase4_dependencies(o,root,src,registry)
  out <- fresh_directory(need(o,"out"))
  write.csv(deps$report,file.path(out,"dependencies.csv"),row.names=FALSE)
  if(o$command=="check-figures") {
    writeLines("DEPENDENCY_INSPECTION_ONLY_NO_SCIENTIFIC_CODE_EXECUTED",file.path(out,"STATUS"))
    print(deps$report);return(invisible(NULL))
  }
  allow_partial <- o$command=="supplement" && (is.null(o$target) || o$target=="all")
  if(any(deps$report$status=="BLOCKED") && !allow_partial) {
    writeLines("BLOCKED: see dependencies.csv; no scientific execution started",file.path(out,"STATUS"))
    stop("Missing or mismatched dependencies; see ",file.path(out,"dependencies.csv"))
  }
  if(all(deps$report$status=="BLOCKED")) {
    writeLines("BLOCKED: no available targets",file.path(out,"STATUS"));return(invisible(NULL))
  }
  with_figure_log(out,function() {
    phase4_provenance(out,o,root,src,deps)
    if(o$command=="counterfactual") {
      stage <- stage_original(out,root,src,o$data,deps$fits)
      execute_counterfactuals(simulation_selection(o$experiment),stage,out)
    } else execute_figures(o,root,src,deps,out)
  })
  if(any(deps$report$status=="BLOCKED")) writeLines("COMPLETED_WITH_BLOCKED_TARGETS",file.path(out,"STATUS"))
}

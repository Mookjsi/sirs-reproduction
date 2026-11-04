# Pure function definitions shared by the user-invoked CLI and diagnostic utilities.
parse_options <- function(args,extra_allowed=character()) {
  if (!length(args)) stop("A command is required; see phase3_execution_plan.md")
  x <- list(command=args[1]); i <- 2L
  while(i<=length(args)) {
    k <- sub("^--","",args[i])
    if(!startsWith(args[i],"--") || k %in% names(x)) stop("Invalid/duplicate option: ",args[i])
    if(k=="resume") {x[[k]] <- TRUE; i <- i+1L; next}
    if(i==length(args)) stop("Missing option value: ",k)
    x[[k]] <- args[i+1L]; i <- i+2L
  }
  allowed <- c("command","out","data","run","variant","region","cpus","mode",
               "chains","iter","warmup","seed","cache","resume","draws",extra_allowed)
  if(any(!names(x) %in% allowed)) stop("Unknown options: ",paste(setdiff(names(x),allowed),collapse=","))
  x
}
need <- function(o,k) {
  if(is.null(o[[k]]) || !nzchar(o[[k]])) stop("Required: --",k)
  o[[k]]
}
positive_int <- function(x,label,min=1L) {
  y <- suppressWarnings(as.numeric(x))
  if(length(y)!=1 || !is.finite(y) || y!=floor(y) || y<min || y>.Machine$integer.max)
    stop("Invalid integer ",label,": ",x)
  as.integer(y)
}
fresh_directory <- function(path) {
  if(file.exists(path)) stop("Refusing to overwrite existing output: ",path)
  if(!dir.create(path,recursive=TRUE)) stop("Cannot create output directory: ",path)
  normalizePath(path)
}
atomic_rds <- function(value,path) {
  if(file.exists(path)) stop("Refusing to overwrite: ",path)
  tmp <- paste0(path,".partial")
  if(file.exists(tmp)) stop("Partial file already exists: ",tmp)
  saveRDS(value,tmp)
  if(!file.rename(tmp,path)) stop("Atomic rename failed: ",path)
}
hash_file <- function(path) {
  result <- system2("sha256sum",shQuote(normalizePath(path)),stdout=TRUE)
  if(!is.null(attr(result,"status"))) stop("sha256sum failed: ",path)
  strsplit(result," +")[[1]][1]
}
assert_sources <- function(root) {
  manifest <- read.delim(file.path(root,"audit_artifacts/source_manifest.tsv"),check.names=FALSE)
  src <- file.path(root,"source",source_commit)
  for(i in seq_len(nrow(manifest))) {
    f <- file.path(src,manifest$relative_path[i])
    if(hash_file(f)!=manifest$sha256[i]) stop("Pinned source mismatch: ",f)
  }
  src
}
settings <- function(o,row) {
  s <- original_defaults
  for(k in c("chains","iter","warmup","cpus"))
    if(!is.null(o[[k]])) s[[k]] <- positive_int(o[[k]],k,if(k=="warmup") 0L else 1L)
  s$seed <- if(is.null(o$seed)) as.integer(row$seed) else positive_int(o$seed,"seed",0L)
  s$adapt_delta <- row$adapt_delta
  s$mode <- if(is.null(o$mode)) "reproduction" else o$mode
  if(!s$mode %in% c("reproduction","non-reproduction")) stop("Unknown --mode")
  if(s$warmup>=s$iter) stop("Warmup must be less than iter")
  changed <- any(vapply(c("chains","iter","warmup","cpus"),
                        function(k) s[[k]]!=original_defaults[[k]],logical(1))) || s$seed!=row$seed
  if(changed && s$mode=="reproduction")
    stop("Changed chains/iterations/warmup/seed/CPU count requires --mode non-reproduction")
  s
}
with_stage <- function(out,fun) {
  con <- file(file.path(out,"execution.log"),"wt")
  sink(con,split=TRUE); sink(con,type="message")
  on.exit({sink(type="message");sink();close(con)},add=TRUE)
  capture.output(sessionInfo(),file=file.path(out,"sessionInfo.txt"))
  write.csv(installed.packages()[,c("Package","Version","LibPath")],
            file.path(out,"installed_packages.csv"),row.names=FALSE)
  code <- c("configs/defaults.R","configs/regions.csv","scripts/pipeline.R",
            "scripts/pipeline_common.R","scripts/pipeline_actions.R","diagnostics/posterior.R")
  write.csv(data.frame(file=code,sha256=vapply(file.path(REPRO_ROOT,code),hash_file,character(1))),
            file.path(out,"pipeline_code_hashes.csv"),row.names=FALSE)
  writeLines(paste(commandArgs(),collapse="\n"),file.path(out,"command.txt"))
  tryCatch({fun();writeLines("COMPLETED",file.path(out,"STATUS"))},
    error=function(e) {
      writeLines(c("FAILED",conditionMessage(e)),file.path(out,"STATUS"))
      stop(e)
    })
}
load_run <- function(path) {
  if(!file.exists(file.path(path,"COMPLETE"))) stop("Incomplete run: ",path)
  m <- readRDS(file.path(path,"manifest.rds"))
  f <- readRDS(file.path(path,"fit.rds"))
  stopifnot(inherits(f,"stanfit"),f@mode==0L)
  list(fit=f,manifest=m,data=readRDS(file.path(path,"standata.rds")))
}
load_model <- function(row,src,cache,out) {
  f <- file.path(src,"stanmodel",paste0(row$model,".stan"))
  if(!file.copy(f,file.path(out,"model.stan"))) stop("Cannot archive model")
  cached <- if(is.null(cache)) "" else file.path(cache,paste0(row$model,".rds"))
  # Only the existing Phase 2 cache has independently recorded source provenance.
  if(nzchar(cached) && file.exists(cached)) {
    expected <- normalizePath(file.path(REPRO_ROOT,"results/phase2-smoke-20261104/compiled"))
    if(normalizePath(cache)!=expected) stop("Unverified cache; omit --cache to compile original source")
    model <- readRDS(cached)
    normalize_code <- function(x) gsub("[[:space:]]","",x)
    if(normalize_code(model@model_code)!=normalize_code(paste(readLines(f),collapse="\n")))
      stop("Cached model code differs from original")
    return(model)
  }
  rstan::stan_model(file=f,model_name=row$model,auto_write=FALSE)
}

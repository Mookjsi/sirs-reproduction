# Actions are called only by an explicit user invocation of pipeline.sh.
prepare_data <- function(o,root,src,registry) {
  out <- fresh_directory(need(o,"out"))
  with_stage(out,function() {
    pairs <- c("cases.csv"="data/japan_rsv.csv","population.csv"="data/japan_pop.csv",
               "humidity.csv"="data_processed/data_processed_humidity.csv",
               "temperature.csv"="data_processed/data_processed_temperature.csv")
    for(n in names(pairs)) stopifnot(hash_file(file.path(root,"../perturbation/raw_data",n))==
                                     hash_file(file.path(src,pairs[[n]])))
    env <- new.env(parent=globalenv())
    old <- getwd(); on.exit(setwd(old),add=TRUE)
    setwd(file.path(src,"script")); sys.source("script_data.R",envir=env)
    raw <- read.csv(file.path(src,"data/japan_rsv.csv")); raw$week <- pmin(raw$week,52)
    ref <- aggregate(cases~prefecture+year+week,raw,function(x) round(mean(x)))
    actual <- as.data.frame(env$japan_rsv_prefecture)
    compared <- merge(ref,actual,by=c("prefecture","year","week"))
    stopifnot(nrow(compared)==26884,all(compared$cases.x==compared$cases.y),
              sum(table(paste(raw$prefecture,raw$year,raw$week))==2)==94)
    data <- list()
    for(i in seq_len(nrow(registry))) {
      r <- registry[i,]; d <- as.data.frame(env$japan_rsv_island)
      d <- d[as.character(d$island)==r$region,]
      stopifnot(nrow(d)==572,identical(as.integer(d$year),rep(2013:2023,each=52)),
                identical(as.integer(d$week),rep(1:52,11)),!anyNA(d),
                all(is.finite(d$cases)),all(d$cases>=0),all(d$cases==round(d$cases)))
      population <- env$japan_pop_island$pop[env$japan_pop_island$island==r$region]
      stopifnot(length(population)==1,is.finite(population),population>0)
      x <- list(N=572L,Nnonpi=as.integer(r$Nnonpi),week=as.integer(d$week),
                cases=as.integer(d$cases),mu=1/80/52,pop=population,gamma=1)
      if(r$variant=="prepost") x$type <- as.integer((d$year+d$week/52>r$source_break)+1)
      data[[paste(r$variant,r$region,sep="/")]] <- x
    }
    for(n in ls(env,pattern="^japan_")) {
      d <- as.data.frame(env[[n]]); stopifnot(!anyNA(d))
      write.csv(d,file.path(out,paste0(n,".csv")),row.names=FALSE)
    }
    bundle <- list(data=data,registry=registry,commit=source_commit,
                   registry_sha256=hash_file(file.path(root,"configs/regions.csv")),
                   defaults_sha256=hash_file(file.path(root,"configs/defaults.R")),
                   inputs=setNames(vapply(pairs,function(p) hash_file(file.path(src,p)),character(1)),names(pairs)))
    atomic_rds(bundle,file.path(out,"bundle.rds"))
    capture.output(dput(bundle[names(bundle)!="data"]),file=file.path(out,"provenance.txt"))
    cat("PREPARE_COMPLETE: eight original region/variant data lists\n")
  })
}
run_regions <- function(o,root,src,registry) {
  variant <- need(o,"variant")
  if(!variant %in% c("seasonal","prepost","all")) stop("Invalid variant")
  selected <- registry[variant=="all" | registry$variant==variant,,drop=FALSE]
  if(o$command=="run") selected <- selected[selected$region==need(o,"region"),,drop=FALSE]
  if(!nrow(selected)) stop("No original specification for this region/variant; see configs/README.md")
  bundle_path <- normalizePath(need(o,"data")); bundle <- readRDS(file.path(bundle_path,"bundle.rds"))
  stopifnot(bundle$commit==source_commit,identical(bundle$registry,registry),
            bundle$defaults_sha256==hash_file(file.path(root,"configs/defaults.R")))
  # Validate every requested configuration before running the first region.
  configs <- lapply(seq_len(nrow(selected)),function(i) settings(o,selected[i,]))
  output <- path.expand(need(o,"out"))
  if(file.exists(output)) {
    if(!isTRUE(o$resume)) stop("Output exists; --resume required: ",output)
  } else dir.create(output,recursive=TRUE)
  output <- normalizePath(output)
  lock <- file.path(output,".pipeline-lock")
  if(!dir.create(lock,showWarnings=FALSE)) stop("Run lock exists: ",lock)
  on.exit(unlink(lock,recursive=TRUE),add=TRUE)
  writeLines(paste("PID",Sys.getpid()),file.path(lock,"owner.txt"))
  records <- list()
  for(i in seq_len(nrow(selected))) {
    row <- selected[i,]; cfg <- configs[[i]]
    data <- bundle$data[[paste(row$variant,row$region,sep="/")]]
    stopifnot(!is.null(data))
    parent <- file.path(output,row$variant,row$region)
    dir.create(parent,recursive=TRUE,showWarnings=FALSE)
    attempts <- list.dirs(parent,full.names=TRUE,recursive=FALSE)
    completed <- attempts[file.exists(file.path(attempts,"COMPLETE"))]
    if(length(completed)) {
      last <- tail(sort(completed),1)
      prior <- readRDS(file.path(last,"manifest.rds"))
      if(!identical(prior$settings,cfg) || !identical(prior$config,row) ||
         prior$data_sha256!=hash_file(file.path(bundle_path,"bundle.rds")))
        stop("Resume settings/data mismatch: ",last)
      if(!isTRUE(o$resume)) stop("Completed result exists: ",last)
      cat("SKIP_COMPLETED",last,"\n"); records[[i]] <- data.frame(region=row$region,variant=row$variant,path=last,status="SKIPPED_COMPLETED")
      next
    }
    attempt <- fresh_directory(file.path(parent,sprintf("attempt-%03d",length(attempts)+1L)))
    with_stage(attempt,function() {
      manifest <- list(config=row,settings=cfg,commit=source_commit,
                        model_sha256=hash_file(file.path(src,"stanmodel",paste0(row$model,".stan"))),
                        data_sha256=hash_file(file.path(bundle_path,"bundle.rds")),
                        rstan=as.character(packageVersion("rstan")),
                        StanHeaders=as.character(packageVersion("StanHeaders")))
      atomic_rds(manifest,file.path(attempt,"manifest.rds"))
      capture.output(dput(manifest),file=file.path(attempt,"manifest.txt"))
      atomic_rds(data,file.path(attempt,"standata.rds"))
      model <- load_model(row,src,o$cache,attempt)
      options(mc.cores=cfg$cpus)
      warnings <- character()
      timing <- system.time(fit <- withCallingHandlers(
        rstan::sampling(model,data=data,chains=cfg$chains,cores=cfg$cpus,iter=cfg$iter,
          warmup=cfg$warmup,thin=cfg$thin,seed=cfg$seed,init=cfg$init,init_r=cfg$init_r,
          control=list(adapt_delta=cfg$adapt_delta,max_treedepth=cfg$max_treedepth),
          refresh=100,sample_file=file.path(attempt,"chain.csv")),
        warning=function(w) {warnings <<- c(warnings,conditionMessage(w)); invokeRestart("muffleWarning")}))
      writeLines(warnings,file.path(attempt,"warnings.txt"))
      if(fit@mode!=0L) stop("Stan did not return sampling draws")
      arr <- as.array(fit)
      stopifnot(identical(dim(arr)[1:2],c(cfg$iter-cfg$warmup,cfg$chains)),all(is.finite(arr)))
      rm(arr)
      atomic_rds(fit,file.path(attempt,"fit.rds"))
      # Compatible object name for the authors' original downstream scripts.
      suffix <- if(row$variant=="seasonal") "npi" else "npi2"
      objname <- paste0("stanfit_sirs_",tolower(row$region),"_",suffix)
      ee <- new.env(); ee[[objname]] <- fit
      save(list=objname,envir=ee,file=file.path(attempt,paste0(objname,".rda")))
      capture.output(dput(timing),file=file.path(attempt,"timing.txt"))
      writeLines("SAMPLING_COMPLETED_NOT_CONVERGENCE_CERTIFIED",file.path(attempt,"COMPLETE"))
      cat("SAMPLING_COMPLETE",row$variant,row$region,"\n")
    })
    records[[i]] <- data.frame(region=row$region,variant=row$variant,path=attempt,status="COMPLETED")
  }
  index <- file.path(output,paste0("run-index-",format(Sys.time(),"%Y%m%dT%H%M%S"),"-",Sys.getpid(),".csv"))
  if(file.exists(index)) stop("Index already exists")
  write.csv(do.call(rbind,records),index,row.names=FALSE)
}
postprocess <- function(o,root) {
  run <- normalizePath(need(o,"run")); obj <- load_run(run)
  out <- fresh_directory(need(o,"out"))
  with_stage(out,function() {
    atomic_rds(obj$manifest,file.path(out,"input_manifest.rds"))
    if(o$command=="extract") extract_results(obj,out)
    if(o$command=="diagnose") diagnose_results(obj,out)
    if(o$command=="plots") diagnostic_plots(obj,out)
    if(o$command=="ppc") predictive_checks(obj,out,
      positive_int(if(is.null(o$draws)) "200" else o$draws,"draws"),
      positive_int(if(is.null(o$seed)) "102" else o$seed,"seed",0L))
  })
}

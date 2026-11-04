# Invoke original deterministic scripts; record their arguments/states without changing equations.
simulation_selection <- function(experiment) {
  if(experiment=="figure3") return(c("Honshu","Shikoku","Kyushu","interpolate"))
  if(experiment=="all") return(c("Honshu","Shikoku","Kyushu","Hokkaido","Ryukyu","interpolate"))
  if(experiment %in% c("Honshu","Shikoku","Kyushu","Hokkaido","Ryukyu","interpolate")) return(experiment)
  stop("Unknown --experiment: ",experiment)
}
simulation_regions <- function(names) unique(unlist(lapply(names,function(n)
  if(n=="interpolate") c("Honshu","Kyushu") else n)))
save_simulation_tape <- function(name,run,out) {
  env <- run$env; calls <- run$tape$calls
  n <- length(calls); expected <- if(name=="interpolate") 3362L else 441L
  stopifnot(n==expected)
  # Store every trajectory and exact argument list before any plotting stage.
  atomic_rds(calls,file.path(out,paste0(name,"_arguments_and_states.rds")))
  metrics <- lapply(seq_along(calls),function(i) {
    x <- calls[[i]]; y <- x$states$cases[-1]
    stopifnot(nrow(x$states)==53L,length(y)==52L,all(is.finite(y)),all(y>=0),sum(y)>0,
              all(is.finite(as.matrix(x$states[,c("S","I","R")]))),
              all(as.matrix(x$states[,c("S","I","R")])>=0))
    offset <- if(name=="Ryukyu") 0 else 26
    data.frame(call=i,S0=x$arguments$S0,I0=x$arguments$I0,
      peak_index=which.max(y),cog_index=sum(y*(1:52))/sum(y),
      source_plot_cog=sum(y*(1:52))/sum(y)+offset,
      peak_ties=sum(y==max(y)),total_reported=sum(y))
  })
  metrics <- do.call(rbind,metrics)
  original_table <- env[[paste0("simulate_sirs_",tolower(name))]]
  stopifnot(nrow(original_table)==if(name=="interpolate") 1681L*52L else 441L*52L)
  if(name!="interpolate") stopifnot(identical(as.numeric(original_table$cases),
    as.numeric(unlist(lapply(calls,function(x) x$states$cases[-1])))))
  write.csv(metrics,file.path(out,paste0(name,"_timing_metrics.csv")),row.names=FALSE)
  if(name=="interpolate") {
    low <- metrics[seq(1,n,by=2),]; high <- metrics[seq(2,n,by=2),]
    grid <- env$paramdata
    paired <- data.frame(interp=grid[[1]],amp=grid[[2]],peak_low=low$peak_index,
      peak_high=high$peak_index,peak_advance=low$peak_index-high$peak_index,
      cog_low=low$cog_index,cog_high=high$cog_index,
      cog_advance=low$cog_index-high$cog_index)
    reference <- unique(env$simulate_sirs_interpolate[,c("interp","amp","shift_cases")])
    check <- merge(paired,reference,by=c("interp","amp"))
    stopifnot(nrow(check)==1681L,all(check$peak_advance==check$shift_cases))
    write.csv(paired,file.path(out,"interpolation_paired_metrics.csv"),row.names=FALSE)
    writeLines(paste("Paired peak shifts outside original 12..18 display scale:",
                     sum(paired$peak_advance<12 | paired$peak_advance>18)),
               file.path(out,"interpolation_display_clipping.txt"))
    profile <- mget(c("interp_vec","amp_vec","I0","beta_smooth_honshu","beta_smooth_kyushu",
                      "seas_smooth_honshu","seas_smooth_kyushu","amp_honshu","amp_kyushu"),
                    envir=env,inherits=FALSE)
    atomic_rds(profile,file.path(out,"interpolation_profiles.rds"))
  }
  atomic_rds(list(source_script=paste0("simulate_sirs/simulate_sirs_",tolower(name),".R"),
    source_horizon=53L,incidences_per_trajectory=52L,trajectory_count=n,
    posterior_selection="coordinate-wise medians: summary columns 6",
    metrics_note="Peak index is first maximum; CoG is case-weighted mean. They are different.",
    ryukyu_indexing_note=if(name=="Ryukyu")
      "Original simulator uses week c(1:52,1), drops first case, labels output 1:52 unchanged." else "",
    grid=env$paramdata),file.path(out,paste0(name,"_metadata.rds")))
}
execute_counterfactuals <- function(names,stage,out) {
  dir.create(file.path(out,"simulation_arrays"))
  for(name in names) {
    run <- original_environment(record_simulator=TRUE)
    script <- file.path(stage,"simulate_sirs",paste0("simulate_sirs_",tolower(name),".R"))
    visible <- evaluate_original(script,run$env)
    save_simulation_tape(name,run,file.path(out,"simulation_arrays"))
    stopifnot(file.exists(file.path(stage,"simulate_sirs",simulation_file(name))))
    atomic_rds(visible,file.path(out,"simulation_arrays",paste0(name,"_visible_results.rds")))
  }
  atomic_rds(list(names=names,stage_directory=stage),file.path(out,"simulation_catalog.rds"))
  files <- file.path("workspace/simulate_sirs",vapply(names,simulation_file,character(1)))
  write.csv(data.frame(name=names,file=files,
    sha256=vapply(file.path(out,files),hash_file,character(1))),
    file.path(out,"simulation_hashes.csv"),row.names=FALSE)
  writeLines("SIMULATIONS_COMPLETE",file.path(out,"SIMULATIONS_COMPLETE"))
}

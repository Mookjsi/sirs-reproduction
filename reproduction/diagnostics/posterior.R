# Utilities for explicit, user-invoked analysis of completed original-model fits.
inferred_names <- function(names) {
  grep("^(S0|I0|rho|sigma|phi|tau|omega|sigma_npi|beta(2)?\\[[0-9]+\\]|npi\\[[0-9]+\\])$",names,value=TRUE)
}
extract_results <- function(obj,out) {
  ss <- rstan::summary(obj$fit)$summary
  stopifnot(identical(colnames(ss)[c(4,6,8)],c("2.5%","50%","97.5%")))
  write.csv(data.frame(parameter=rownames(ss),ss,check.names=FALSE),
            file.path(out,"posterior_summary.csv"),row.names=FALSE)
  for(v in c("S","I","R","C","npieff","beta","beta2")) {
    ids <- grep(paste0("^",v,"\\["),rownames(ss))
    if(!length(ids)) next
    d <- data.frame(index=seq_along(ids),median=ss[ids,"50%"],
                    lower=ss[ids,"2.5%"],upper=ss[ids,"97.5%"])
    if(length(ids)==obj$data$N) {
      d$year <- rep(2013:2023,each=52); d$week <- obj$data$week
      if(v=="S") {
        d$proportion_median <- d$median/obj$data$pop
        d$proportion_lower <- d$lower/obj$data$pop; d$proportion_upper <- d$upper/obj$data$pop
      }
    }
    write.csv(d,file.path(out,paste0(v,"_summary.csv")),row.names=FALSE)
  }
  if(obj$manifest$config$variant=="prepost") {
    d <- rstan::extract(obj$fit,pars=c("beta","beta2"))
    ratio <- rowMeans(d$beta2)/rowMeans(d$beta)
    q <- quantile(ratio,c(.025,.5,.975))
    write.csv(data.frame(probability=c(.025,.5,.975),ratio=unname(q),
                         percent_increase=100*(unname(q)-1)),
              file.path(out,"transmission_change.csv"),row.names=FALSE)
  }
  # fit.rds and original-named .rda are the canonical full posterior storage.
  cat("EXTRACTION_COMPLETE\n")
}
diagnose_results <- function(obj,out) {
  arr <- as.array(obj$fit)
  finite <- all(is.finite(arr))
  vars <- inferred_names(dimnames(arr)[[3]])
  d <- posterior::summarise_draws(posterior::as_draws_array(arr[,,vars,drop=FALSE]),
                                   "rhat","ess_bulk","ess_tail")
  write.csv(as.data.frame(d),file.path(out,"rank_diagnostics.csv"),row.names=FALSE)
  old <- rstan::summary(obj$fit)$summary
  write.csv(data.frame(parameter=rownames(old),n_eff=old[,"n_eff"],Rhat=old[,"Rhat"]),
            file.path(out,"rstan_legacy_diagnostics.csv"),row.names=FALSE)
  samplers <- rstan::get_sampler_params(obj$fit,inc_warmup=FALSE)
  per_chain <- lapply(seq_along(samplers),function(i) {
    s <- samplers[[i]]
    write.csv(s,file.path(out,paste0("sampler_chain_",i,".csv")),row.names=FALSE)
    e <- s[,"energy__"]
    data.frame(chain=i,draws=nrow(s),finite=all(is.finite(s)),
      divergences=sum(s[,"divergent__"]),
      depth_hits=sum(s[,"treedepth__"]>=obj$manifest$settings$max_treedepth),
      ebfmi=if(length(e)>1 && var(e)>0) mean(diff(e)^2)/var(e) else NA_real_)
  })
  per_chain <- do.call(rbind,per_chain)
  write.csv(per_chain,file.path(out,"chain_diagnostics.csv"),row.names=FALSE)
  expected <- c(obj$manifest$settings$iter-obj$manifest$settings$warmup,
                obj$manifest$settings$chains)
  dimensions_ok <- identical(dim(arr)[1:2],as.integer(expected))
  qc <- list(draws_finite=finite,dimensions_ok=dimensions_ok,
    at_least_four_chains=dim(arr)[2]>=4,
    rank_rhat_pass=all(is.finite(d$rhat)) && all(d$rhat<=1.01),
    ess_bulk_pass=all(is.finite(d$ess_bulk)) && all(d$ess_bulk>=400),
    ess_tail_pass=all(is.finite(d$ess_tail)) && all(d$ess_tail>=400),
    divergences_pass=all(per_chain$divergences==0),
    treedepth_pass=all(per_chain$depth_hits==0),
    bfmi_pass=all(is.finite(per_chain$ebfmi)) && all(per_chain$ebfmi>=.3))
  qc$overall <- if(all(unlist(qc))) "PASS_DECLARED_DIAGNOSTICS" else "REVIEW_REQUIRED"
  qc$mode <- obj$manifest$settings$mode
  atomic_rds(qc,file.path(out,"quality_checks.rds"))
  capture.output(dput(qc),file=file.path(out,"quality_checks.txt"))
  cat("DIAGNOSTICS_COMPLETE",qc$overall,"\n")
}
diagnostic_plots <- function(obj,out) {
  vars <- c("S0","I0","rho","sigma","phi","tau","omega","sigma_npi","beta[1]")
  a <- as.array(obj$fit,pars=vars)
  grDevices::pdf(file.path(out,"trace_plots.pdf"),width=10,height=7)
  tryCatch({
    par(mfrow=c(3,3),mar=c(3,3,2,1))
    for(v in vars) matplot(a[,,v,drop=FALSE][,,1],type="l",lty=1,
                           main=v,xlab="Retained draw",ylab="Value")
  },finally=dev.off())
  samplers <- rstan::get_sampler_params(obj$fit,inc_warmup=FALSE)
  grDevices::pdf(file.path(out,"sampler_plots.pdf"),width=10,height=7)
  tryCatch({
    for(i in seq_along(samplers)) {
      s <- samplers[[i]]; par(mfrow=c(2,2))
      plot(s[,"energy__"],type="l",main=paste("Chain",i,"energy"),xlab="Draw",ylab="Energy")
      hist(s[,"treedepth__"],main="Tree depth",xlab="Depth")
      plot(s[,"accept_stat__"],type="l",main="Acceptance",xlab="Draw",ylab="Acceptance statistic")
      x <- a[,i,"S0"]; y <- a[,i,"rho"]
      plot(x,y,col=ifelse(s[,"divergent__"]==1,"red","gray40"),pch=16,
           main="Red points: divergences",xlab="S0",ylab="rho")
    }
  },finally=dev.off())
  cat("PLOTS_COMPLETE\n")
}
predictive_checks <- function(obj,out,n_draws,seed) {
  # Additional diagnostic only: conditional observation replicates from the original NB2
  # likelihood. This does not simulate SIRS trajectories or change the fitted model.
  draws <- rstan::extract(obj$fit,pars=c("C","phi"),permuted=TRUE)
  set.seed(seed)
  ids <- sort(sample.int(nrow(draws$C),min(n_draws,nrow(draws$C)),replace=FALSE))
  mu <- draws$C[ids,-1,drop=FALSE] # The original likelihood omits observation 1.
  phi <- draws$phi[ids]
  stopifnot(all(is.finite(mu)),all(mu>=0),all(is.finite(phi)),all(phi>0))
  yrep <- matrix(rnbinom(length(mu),mu=as.vector(mu),size=rep(phi,ncol(mu))),
                  nrow=nrow(mu),ncol=ncol(mu))
  stopifnot(all(is.finite(yrep)))
  y <- obj$data$cases[-1]
  q <- apply(yrep,2,quantile,c(.025,.5,.975))
  table <- data.frame(index=2:obj$data$N,observed=y,lower=q[1,],median=q[2,],upper=q[3,])
  write.csv(table,file.path(out,"predictive_intervals.csv"),row.names=FALSE)
  stats <- function(x) c(total=sum(x),maximum=max(x),zero_fraction=mean(x==0))
  replicated <- t(apply(yrep,1,stats)); observed <- stats(y)
  checks <- data.frame(statistic=names(observed),observed=observed,
    posterior_predictive_tail_probability=colMeans(sweep(replicated,2,observed,">=")))
  write.csv(checks,file.path(out,"predictive_checks.csv"),row.names=FALSE)
  atomic_rds(list(yrep=yrep,posterior_draw_ids=ids,seed=seed,indices=2:obj$data$N),
              file.path(out,"observation_replicates.rds"))
  grDevices::pdf(file.path(out,"predictive_checks.pdf"),width=11,height=6)
  tryCatch({
    plot(table$index,y,type="n",ylim=range(c(y,table$upper)),xlab="Weekly observation index",
         ylab="Reported cases",main="Conditional observation PPC; first observation excluded")
    polygon(c(table$index,rev(table$index)),c(table$lower,rev(table$upper)),
             col="gray85",border=NA)
    lines(table$index,table$median,col="red"); points(table$index,y,pch=16,cex=.4)
  },finally=dev.off())
  writeLines(c("Additional observation-model diagnostic, not a published figure.",
    "Conditioned on fitted latent incidence; not an out-of-sample forecast or epidemic simulation.",
    paste("Replicates:",length(ids),"Seed:",seed),
    paste("Pointwise 95% coverage:",mean(y>=table$lower & y<=table$upper))),
    file.path(out,"PPC_NOTES.txt"))
  cat("PPC_COMPLETE\n")
}

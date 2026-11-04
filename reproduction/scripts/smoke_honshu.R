# This short chain checks execution only; it cannot support scientific inference.
root <- normalizePath("reproduction")
out <- file.path(root,"results/phase2-smoke-20261104")
stopifnot(!file.exists(file.path(out,"honshu_smoke_fit.rds")))
library(rstan)
options(mc.cores=1)
RcppParallel::setThreadOptions(numThreads=1)
model <- readRDS(file.path(out,"compiled/sirs_npi.rds"))
data <- readRDS(file.path(out,"standata.rds"))$Honshu
init <- list(S0=0.08,I0=0.0001,rho=0.01,beta=rep(8,52),sigma=0.2,
             phi=10,tau=100,omega=10,npi=rep(1,data$N-data$Nnonpi),sigma_npi=0.02)
fixed <- sampling(model,data=data,chains=1,cores=1,iter=1,warmup=0,
                  algorithm="Fixed_param",init=list(init),seed=102,refresh=1)
u <- unconstrain_pars(fixed,init)
stopifnot(is.finite(log_prob(fixed,u)),all(is.finite(grad_log_prob(fixed,u))))
fixed_draw <- extract(fixed)
source(file.path(root,"source/475c7dcdadc12987033d332b101f025625074301/R/simulate_sirs.R"))
sim <- simulate_sirs(beta=init$beta,week=data$week,mu=data$mu,gamma=data$gamma,
                     omega=init$omega,delta=1/init$tau,rho=init$rho,npieff=rep(1,data$N),
                     pop=data$pop,S0=init$S0,I0=init$I0,tmax=data$N)
errors <- sapply(c("S","I","R"),function(v) max(abs(fixed_draw[[v]][1,]-sim[[v]])))
errors <- c(errors,C=max(abs(fixed_draw$C[1,-1]-sim$cases[-1])))
stopifnot(all(errors<1e-6),is.na(sim$cases[1]),fixed_draw$C[1,1]==0)
write.csv(data.frame(variable=names(errors),max_absolute_error=errors),
          file.path(out,"stan_R_parity.csv"),row.names=FALSE)
saveRDS(fixed,file.path(out,"honshu_fixed_parameter_check.rds"))
warnings <- character()
elapsed <- system.time(fit <- withCallingHandlers(
  sampling(model,data=data,chains=1,cores=1,iter=60,warmup=40,thin=1,
           seed=102,init=list(init),refresh=10,
           control=list(adapt_delta=0.9,max_treedepth=8),
           sample_file=file.path(out,"honshu_smoke_draws.csv")),
  warning=function(w) {warnings <<- c(warnings,conditionMessage(w)); invokeRestart("muffleWarning")}))
saveRDS(fit,file.path(out,"honshu_smoke_fit.rds"))
a <- as.array(fit)
stopifnot(identical(dim(a)[1:2],c(20L,1L)),all(is.finite(a)))
draw <- extract(fit)
for (v in c("S","I","R","C","npieff")) {
  stopifnot(identical(dim(draw[[v]]),c(20L,572L)),
            all(is.finite(draw[[v]])),all(draw[[v]]>=0))
}
stopifnot(identical(dim(draw$beta),c(20L,52L)),
          identical(dim(draw$npi),c(20L,208L)))
sampler <- get_sampler_params(fit,inc_warmup=FALSE)[[1]]
stopifnot(all(is.finite(sampler)))
write.csv(sampler,file.path(out,"sampler_diagnostics.csv"),row.names=FALSE)
ss <- summary(fit)$summary
stopifnot(identical(colnames(ss)[c(4,6,8)],c("2.5%","50%","97.5%")))
write.csv(ss,file.path(out,"summary_SMOKE_ONLY.csv"))
energy <- sampler[,"energy__"]
diagnostics <- list(status="PASS_EXECUTION_ONLY",island="Honshu",N=data$N,
  iter=60,warmup=40,retained=20,chains=1,cores=1,seed=102,adapt_delta=0.9,
  max_treedepth=8,initialization="explicit valid point; smoke only",
  array_dimensions=dim(a),all_retained_values_finite=TRUE,
  state_dimensions=c(20L,572L),beta_dimensions=dim(draw$beta),npi_dimensions=dim(draw$npi),
  divergences=sum(sampler[,"divergent__"]),
  max_depth_hits=sum(sampler[,"treedepth__"]>=8),
  ebfmi=mean(diff(energy)^2)/var(energy),
  parity_max_absolute_error=errors,elapsed_seconds=elapsed[["elapsed"]],
  warnings=warnings,scientific_inference_valid=FALSE)
saveRDS(diagnostics,file.path(out,"smoke_diagnostics.rds"))
capture.output(dput(diagnostics),file=file.path(out,"smoke_diagnostics.txt"))
writeLines(warnings,file.path(out,"smoke_warnings.txt"))
print(diagnostics)
cat("SMOKE_PASS_EXECUTION_ONLY\n")

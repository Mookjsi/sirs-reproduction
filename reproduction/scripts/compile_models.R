# Compile each original specification serially without sampling.
root <- normalizePath("reproduction")
out <- file.path(root,"results/phase2-smoke-20261104")
dir.create(file.path(out,"compiled"),recursive=TRUE,showWarnings=FALSE)
library(rstan)
options(mc.cores=1)
RcppParallel::setThreadOptions(numThreads=1)
rstan_options(auto_write=FALSE)
files <- list.files(file.path(root,"work/475c7dcdadc12987033d332b101f025625074301/stanmodel"),
                    pattern="[.]stan$",full.names=TRUE)
for (f in files) {
  name <- sub("[.]stan$","",basename(f))
  dest <- file.path(out,"compiled",paste0(name,".rds"))
  if (file.exists(dest)) {
    cat("Already compiled:",name,"\n")
    next
  }
  cat("STANC_BEGIN",name,"\n")
  translated <- stanc(file=f,model_name=name)
  stopifnot(translated$status)
  writeLines(translated$cppcode,file.path(out,"compiled",paste0(name,".hpp")))
  cat("COMPILE_BEGIN",name,"\n")
  elapsed <- system.time(model <- stan_model(stanc_ret=translated,model_name=name,
                                             auto_write=FALSE,verbose=FALSE))
  saveRDS(model,dest)
  writeLines(paste(names(elapsed),elapsed),file.path(out,"compiled",paste0(name,"_timing.txt")))
  cat("COMPILE_PASS",name,"elapsed",elapsed[["elapsed"]],"\n")
}
stopifnot(length(list.files(file.path(out,"compiled"),pattern="[.]rds$"))==4)
capture.output(sessionInfo(),file=file.path(out,"sessionInfo.txt"))
write.csv(installed.packages()[,c("Package","Version","LibPath")],
          file.path(out,"installed_packages.csv"),row.names=FALSE)
cat("ALL_MODELS_COMPILE_PASS\n")

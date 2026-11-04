# Install only required dependencies into this reproduction's private library.
root <- normalizePath("reproduction", mustWork=TRUE)
lib <- file.path(root, "environment/library")
.libPaths(c(lib, .Library))
options(repos=c(CRAN="https://cloud.r-project.org"), Ncpus=1, timeout=600)
Sys.setenv(MAKEFLAGS="-j1", OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1",
           MKL_NUM_THREADS="1", RCPP_PARALLEL_NUM_THREADS="1")
downloads <- file.path(root, "environment/downloads")
ap <- available.packages()
write.csv(ap, file.path(root,"environment/cran_available_packages.csv"))
required <- c("inline","gridExtra","Rcpp","RcppParallel","loo","pkgbuild",
              "QuickJSR","ggplot2","RcppEigen","BH","tidyr","dplyr","egg","readxl")
deps <- unique(c(unlist(tools::package_dependencies(required, db=ap,
                       which=c("Depends","Imports","LinkingTo"),recursive=TRUE)),required))
deps <- setdiff(deps,c("R","rstan","StanHeaders",rownames(installed.packages())))
if(length(deps)) install.packages(deps, lib=lib, dependencies=NA, destdir=downloads)
for (pkg in c("StanHeaders","rstan")) {
  if (!requireNamespace(pkg,quietly=TRUE) || packageVersion(pkg)!="2.32.6") {
    install.packages(file.path(downloads,paste0(pkg,"_2.32.6.tar.gz")),
                     repos=NULL,type="source",lib=lib)
  }
}
for (pkg in c(required,"StanHeaders","rstan")) stopifnot(requireNamespace(pkg,quietly=TRUE))
stopifnot(packageVersion("rstan")=="2.32.6",packageVersion("StanHeaders")=="2.32.6")
write.csv(installed.packages()[,c("Package","Version","LibPath")],
          file.path(root,"environment/installed_packages.csv"),row.names=FALSE)
capture.output(sessionInfo(),file=file.path(root,"environment/setup_sessionInfo.txt"))
cat("SETUP_PASS\n")

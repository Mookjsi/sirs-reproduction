# Optional map-only dependencies. User invocation installs packages, not analyses.
root <- normalizePath("reproduction")
lib <- file.path(root,"environment/library")
.libPaths(c(lib,.Library))
options(repos=c(CRAN="https://cloud.r-project.org"),Ncpus=1,timeout=600)
Sys.setenv(MAKEFLAGS="-j1",OMP_NUM_THREADS="1",OPENBLAS_NUM_THREADS="1",MKL_NUM_THREADS="1")
packages <- setdiff(c("maps","mapdata","ggfortify"),rownames(installed.packages()))
if(length(packages)) install.packages(packages,lib=lib,dependencies=NA,
                                     destdir=file.path(root,"environment/downloads"))
stopifnot(all(vapply(c("maps","mapdata","ggfortify"),requireNamespace,logical(1),quietly=TRUE)))

#!/usr/bin/env bash
set -euo pipefail
REPRO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export R_LIBS_USER="$REPRO_ROOT/environment/library"
export R_MAKEVARS_USER="$REPRO_ROOT/environment/Makevars"
export TMPDIR="$REPRO_ROOT/environment/tmp"
export MAKEFLAGS=-j1
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
export RCPP_PARALLEL_NUM_THREADS=1 STAN_NUM_THREADS=1
cd "$REPRO_ROOT/.."
exec nice -n 10 Rscript --vanilla "$@"

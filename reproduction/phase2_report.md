# Phase 2 environment and smoke-test report

**Status: COMPLETE — execution checks passed; scientific inference remains unperformed.**
Run: `results/phase2-smoke-20261104/`. No full inference, original counterfactual grids,
or scientific comparisons were run. No existing experiments were stopped or modified.

## Environment

Private R library: `environment/library/`; R 4.5.3 on Ubuntu 24.04.3, x86_64.
Paper-matched rstan **2.32.6**, StanHeaders **2.32.6**; rstan reports Stan **2.32.2**.
Compiler: GCC/G++ 13.3.0. Main dependencies include Rcpp 1.1.2, RcppEigen 0.3.4.0.2,
RcppParallel 6.2.1, BH 1.90.0-1, QuickJSR 1.11.0, dplyr 1.2.1, tidyr 1.3.2,
ggplot2 4.0.3, readxl 1.6.0, egg 0.4.5, gridExtra 2.3.1; mgcv 1.9-4 is bundled with R.
These dependency/R versions are recorded, not claimed identical to the authors' whole environment.

Source installation was serial (`MAKEFLAGS=-j1`); C++ flags `-O1 -g0` reduce build cost.
BLAS, OpenMP, RcppParallel/TBB and Stan threads were limited to 1; R jobs used niceness 10.
No system R packages or global compiler configuration were changed. CRAN initially failed
inside the network sandbox (`curl: (6) Could not resolve host: cloud.r-project.org`);
approved network access resolved it. There were no failed package installations.

Evidence: `environment/logs/setup.log` ends with `SETUP_PASS`;
`environment/installed_packages.csv`, `setup_sessionInfo.txt`, `toolchain.txt`,
`download_manifest.tsv` record versions, compiler and source-archive SHA-256 hashes.
The package repository index used for resolution and downloaded package archives are retained.
The installed library is private but includes compiled artifacts tied to this R/platform.

## Source preservation and compatibility fixes

All 54 original tracked files still match pinned commit
`475c7dcdadc12987033d332b101f025625074301`. `source/<commit>/` is the untouched snapshot;
`work/<commit>/` is the execution copy. All four Stan files in both are byte-identical
to their upstream versions; no syntax translation was necessary with rstan 2.32.6.

Applied only in the execution copy: added missing `R/firstup.R`; removed four unused
assignments referencing undefined `japan_birth_island`. Fixed paths are managed by runners,
not edits to scientific calculations. Exact diffs/hashes are in `patches/`.
No sensitivity break-date changes were made; the paper/code discrepancy remains unresolved.
Zenodo archive equivalence is still unverified; this run is tied to the audited local commit.

## Input verification and preprocessing

All four `perturbation/raw_data/` CSVs remain byte-identical to the expected authors'
inputs and Phase 1 manifests. The original unmodified `script/script_data.R` executed.
Independent base-R aggregation exactly matched its prefecture case output, including
94 week-52/53 duplicate groups averaged and rounded, not summed.

- 26,978 input case rows → 26,884 prefecture-week rows; 47 prefectures × 572 weeks.
- Five islands × 572 ordered weeks (2013–2023, weeks 1–52).
- Nonnegative integer cases and no missing values in checked processed tables.
- Audited island populations match exactly; each climate island table has 1,865 rows
  (five islands × 373 supplied weekly dates), with finite values and no missing cells.
- All five original baseline Stan input lists exported to `standata.rds`, including
  Nnonpi 208 for Hokkaido, 312 for Ryukyu and 364 for other islands.

Evidence: `preprocess.log` ends with `PREPROCESS_PASS`; `preprocessing.rds`,
`standata.rds` and processed CSVs are in the run directory.
The original loader's dplyr regrouping messages are retained; no preprocessing semantics
were changed to silence them. Hourly/daily ERA5 reconstruction remains blocked by absent
primary inputs; this pipeline starts with the authors' supplied weekly tables.

## Stan compilation

All four specifications passed stanc and C++ compilation, sequentially:

| Original specification | Elapsed build seconds |
|---|---:|
| `sirs_npi_tweak.stan` | 67.218 |
| `sirs_npi_tweak2.stan` | 69.735 |
| `sirs_npi.stan` | 69.590 |
| `sirs_npi2.stan` | 92.398 |

Evidence: `compile_models.log` ends with `ALL_MODELS_COMPILE_PASS`; `compiled/` contains
generated C++ headers, serialized compiled models and individual timings. At session-info
capture, `timedatectl` could not connect to the container system bus (status 1). This is
an environment metadata warning, not a compilation or numerical failure, and is retained.

## Fixed-parameter numerical check

On actual Honshu data, the compiled original baseline model has finite log density and
finite gradients at an explicitly valid parameter point. One fixed-parameter evaluation
was compared with the authors' unchanged deterministic R simulator over all 572 weeks.
The first Stan incidence is zero; the first R incidence is NA; comparison excludes that
intentional difference. Maximum absolute differences were:

| Output | Maximum absolute difference |
|---|---:|
| S | 1.490116e-8 |
| I | 1.024455e-8 |
| R | 4.172325e-7 |
| Expected reported incidence C | 7.094059e-11 |

All passed the declared absolute tolerance of 1e-6 individuals/cases. This is numerical
agreement between the original implementations at a fixed point, not agreement with
published posterior estimates. See `stan_R_parity.csv` and `honshu_fixed_parameter_check.rds`.

## Honshu end-to-end smoke test

Actual 572-week Honshu inputs; original baseline Stan specification and likelihood.
Smoke-only configuration: seed 102, one chain/core, 60 iterations, 40 warmup, thin 1,
adapt_delta 0.90, max_treedepth 8. Initialization is explicit and saved in the runner:
S0=.08, I0=.0001, rho=.01, beta=8, sigma=.2, phi=10, tau=100, omega=10,
npi=1 and sigma_npi=.02. No posterior estimates from a separate model were used.

| Check | Observed |
|---|---|
| Retained draw array | 20 × 1 chain × 3,130 scalar outputs, all finite |
| S, I, R, C, npieff | each 20 × 572, finite and nonnegative |
| beta | 20 × 52 |
| npi | 20 × 208 |
| Retained sampler diagnostics | all finite |
| Summary column convention | columns 4/6/8 are 2.5%/50%/97.5% |
| Divergences after warmup | 0 |
| Depth-8 hits after warmup | 19 / 20 |
| E-BFMI | 0.456756 |
| Sampler-reported runtime | 3.933 s warmup + 3.203 s sampling |
| R sampling call elapsed time | 11.493 s |

The short chain triggered adaptation-window adjustment, depth-limit, R-hat/NA,
low bulk ESS and low tail ESS warnings. **It is not converged or suitable for scientific
inference.** Nonfinite/unavailable convergence summaries for constants or the short chain
are diagnostic limitations; retained draws, states, sampler values and checked gradients
are finite. The log contains no model exceptions or rejected-initial-value messages.
No extra inference was launched to improve these smoke-only diagnostics.

Evidence: `smoke_honshu.log` ends with `SMOKE_PASS_EXECUTION_ONLY`;
`smoke_diagnostics.txt` / `.rds`, `smoke_warnings.txt`, `sampler_diagnostics.csv`,
`honshu_smoke_fit.rds`, and labelled `summary_SMOKE_ONLY.csv`.
The sample CSV retains configuration comments and actual draw rows.

## Completion and boundary

All completion criteria passed: original models compile, original supplied-data preprocessing
succeeds, and one end-to-end island smoke run completes with validated finite outputs.
This establishes a working execution pipeline only. Full convergence, paper figures,
posterior estimates, sensitivity comparisons and counterfactual grids remain unperformed.
Full inference requires the user's next approval and an agreed resource budget.

Exact executed commands: `results/phase2-smoke-20261104/commands.txt`.
Entry scripts: `scripts/prepare_source.py`, `setup_environment.R`, `preprocess.R`,
`compile_models.R`, `smoke_honshu.R`; `run_r.sh` enforces the private environment and
thread limits. `run_phase2.sh` orchestrates the same stages on a fresh run directory.

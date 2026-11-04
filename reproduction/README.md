# Park et al. (2025): original-source reproduction

Status: **Phase 2 COMPLETE: preprocessing, all four original Stan compilations, and
one Honshu smoke run passed execution checks.**
The Phase 3 pipeline is prepared for manual user execution; full inference and
counterfactual grids remain unperformed. Codex has run no
Phase 3 experiments. See [phase2_report.md](phase2_report.md) for earlier executed checks.

The workspace was inspected before resolving paths. From this directory:

- Paper: `../perturbation/nature_paper.pdf` (published Nature Communications article, DOI `10.1038/s41467-025-66184-y`).
- Authors' checkout: `../perturbation/`, origin `https://github.com/parksw3/perturbation.git`.
- Local supplied data: `../perturbation/raw_data/`.
- Audited commit: `475c7dcdadc12987033d332b101f025625074301`.

Read [audit.md](audit.md), then [reproduction_plan.md](reproduction_plan.md).
[comparison.md](comparison.md) records published targets and current blockers;
[patch_log.md](patch_log.md) separates proposed fixes from applied changes.
`figures/` remains reserved; `results/phase2-smoke-20261104/` contains smoke-only outputs.
`audit_artifacts/` contains provenance and read-only inspection evidence, not model results.

## Original workflow and full-inference boundary

Use an isolated copy of the pinned source under this directory, preserving the original checkout.
Install into a project-local R library, targeting the paper's `rstan 2.32.6` and recording
the resolved R, StanHeaders, compiler, and package versions. No lockfile is supplied upstream.
Required main-figure packages: `rstan`, `tidyr`, `dplyr`, `ggplot2`, `egg`, `gridExtra`,
`readxl`, `mgcv`. `lubridate` is additionally required only for rebuilding weekly climate
data from missing daily inputs. Stan dependencies must be resolved by the package installer.
Do not install mapping or stochastic-simulation packages for Figures 1–4 unless needed.

Upstream scripts expect their own subdirectory as the working directory and write outputs
there. A full-inference reproduction runner must run only the isolated, logged compatibility copies,
then collect outputs into `results/<run-id>/` and `figures/<run-id>/` without overwriting files.
These upstream entrypoints provide traceability; use the new CLI for inference:

1. `script/script_data.R` (sourced by downstream scripts).
2. `figure/figure1.R` (observations only).
3. `stanfit_sirs/stanfit_sirs_{honshu,kyushu,shikoku,hokkaido,ryukyu}_npi.R`.
4. `simulate_sirs/simulate_sirs_{honshu,shikoku,kyushu}.R`, then `simulate_sirs_interpolate.R`.
5. `figure/figure_comb_sirs_change.R` (Figure 3, priority).
6. `figure/figure_comb_sirs_npi.R` (Figure 2), `figure/figure_childcare.R` (Figure 4).
7. `stanfit_sirs2/stanfit_sirs_{honshu,kyushu,shikoku}_npi2.R`, then
   `analysis/analysis_beta.R` for the published transmission-change sensitivity analysis.

Full sampling commands are now provided for **the user to execute**, in
[phase3_execution_plan.md](phase3_execution_plan.md). Codex must not launch them.
Original defaults preserve four chains and 4,000 iterations per chain. CPU or sampling
overrides require `--mode non-reproduction`; all deviations are recorded.

## Phase 2 commands

Run from the workspace root. Setup requires CRAN network access; it writes only to this
reproduction's environment. All commands use one thread and private compiler settings.

```bash
python3 reproduction/scripts/prepare_source.py
bash reproduction/scripts/run_r.sh reproduction/scripts/setup_environment.R
bash reproduction/scripts/run_phase2.sh
```

The first setup requires archived `rstan_2.32.6.tar.gz` and
`StanHeaders_2.32.6.tar.gz` in `environment/downloads/`; these have been downloaded from
CRAN's respective package archives. The setup script installs only missing required
packages, then installs those two exact versions. `environment/installed_packages.csv`
records resolved package versions; all downloaded package archives are retained for
reinstallation. Keep compiler binaries and R versions consistent when reusing compiled RDS files.

`source/<commit>/` is the untouched upstream snapshot; `work/<commit>/` contains the
minimal compatibility changes. Exact diffs and hashes are under `patches/`.
The stage runner executes preprocessing, all four original Stan compilations, then one
Honshu smoke chain, with results in `results/phase2-smoke-20261104/`. It refuses to overwrite
existing stage logs. To resume a failed stage, inspect its log and invoke that stage's R
script directly using `run_r.sh`, retaining the prior log under a new name. Completed
preprocessing and smoke outputs are protected against overwrite; compilation skips cached models.

The smoke configuration deliberately differs from production: 1 chain, 60 iterations,
40 warmup, 20 retained, depth 8, explicit initialization; seed 102 and adapt_delta 0.90.
It uses all 572 Honshu weeks, with the original Stan priors, likelihood and state updates.
Smoke summaries are labelled `SMOKE_ONLY` and must not be consumed by original figure scripts
or reported as estimates from the paper. Full sampling settings remain unchanged upstream.

## Phase 2 outcome

- Original preprocessing passed independent case-aggregation and dimension checks.
- All four original Stan models compiled without any Stan source edits.
- Honshu smoke: 20 retained draws using all 572 weeks; all retained outputs finite;
  zero divergences, 19/20 depth-8 hits, E-BFMI 0.456756. Short-chain R-hat/ESS warnings
  remain; these draws are not scientific results and do not establish convergence.
- Fixed-parameter R/Stan trajectory agreement passed an absolute tolerance of 1e-6.

Read the [Phase 2 report](phase2_report.md) for exact checks, limits and artifact paths.
No full sampling or counterfactual grids have been run.

## Phase 3 manual CLI

Implementation is complete and statically checked; the new orchestration has **not** been
run, even with reduced iterations. See the [ordered execution plan](phase3_execution_plan.md)
for exact commands, output/recovery contracts and resource estimates.

```bash
# User execution only; choose a new output root.
bash reproduction/scripts/pipeline.sh prepare --out reproduction/user_runs/paper-run-001/data --cpus 1
bash reproduction/scripts/pipeline.sh run-all --variant all \
  --data reproduction/user_runs/paper-run-001/data \
  --out reproduction/user_runs/paper-run-001/fits --cpus 4 \
  --cache reproduction/results/phase2-smoke-20261104/compiled
```

Commands: `prepare`, `run`, `run-all`, `extract`, `diagnose`, `plots`, `ppc`. Every command
accepts `--out` and `--cpus`. Run commands take `--data` and `--variant`; `run` also takes
`--region`. Postprocessing takes `--run` pointing to a completed attempt. There is no
implicit postprocessing or predictive simulation after sampling.

[Configurations](configs/README.md): five seasonal fits plus the three published pre/post
fits. Hokkaido/Ryukyu pre/post combinations are explicitly unsupported because the authors
provide no such configurations. [Diagnostic utilities](diagnostics/README.md) export
posterior summaries, convergence checks, plots and separately requested conditional NB2 PPCs.
No scientific priors, likelihoods, break dates or model equations have been changed.

Static checks can be repeated without executing pipeline actions:

```bash
python3 reproduction/scripts/check_static.py
```

`phase3_static_validation.txt` records successful parsing and source/configuration checks.
This does not establish runtime success of the new CLI; only the user will run it.

## Phase 4 manual figures and counterfactuals

Figure-generation and original counterfactual runners are implemented, **not executed or
numerically verified by Codex**. See the [Phase 4 execution plan](phase4_execution_plan.md),
[panel dependency map](figure_dependency_map.md), and
[comparison template](figure_comparison_template.md).

The existing CLI adds `check-figures`, `figure`, `counterfactual` and `supplement`, with
explicit --data, --fits, --simulations, --out and --cpus options as required by each action.
It stages and runs original scripts against completed Phase 3 artifacts; it never starts
MCMC, substitutes smoke/synthetic estimates, overwrites outputs or silently uses stale
simulation arrays. `check-figures` only inspects dependencies and metadata.

Published Figure 3 uses **seasonal fits and susceptibility counterfactuals**. Pre/post
transmission estimates belong to **Supplementary Figure S8**, supported separately.
The childcare workbook is present; missing/mismatched inputs block its panels. Optional
S2 mapping packages can be installed manually using setup_figure_extras.R. No new packages
were installed in Phase 4.

The original deterministic simulator, posterior medians, grids, indexing, CoG/argmax
metrics, smoothing and plotting expressions are preserved. Source/paper date and indexing
inconsistencies remain documented. No graphical or numerical reproduction is claimed.

Repeat static-only validation without invoking any scientific action:

```bash
python3 reproduction/scripts/check_figure_static.py
```

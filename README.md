# Park et al. (2025) SIRS reproduction

Source-faithful R/Stan inference, deterministic counterfactual, and figure-generation
workflows for *Interplay between climate and childhood mixing can explain a sudden shift
in RSV seasonality in Japan* (DOI: `10.1038/s41467-025-66184-y`).

Original authors' repository: https://github.com/parksw3/perturbation

Pinned upstream commit: `475c7dcdadc12987033d332b101f025625074301`.
The authors' source is retrieved separately and preserved unchanged. Their MIT license
remains in the upstream checkout. No ownership of the authors' code/data is implied.

This repository contains the current reproduction scripts, configurations, provenance
manifests, compatibility patches and documentation. Installed R packages, compiled models,
upstream source copies, the supplied paper PDF, posterior draws, simulations and generated
figures are not committed. Historical reports describe checks made in the original local
workspace; they do not certify a fresh clone or scientific reproduction.

## Set up a fresh clone

Run every command from this repository's root. Absolute `/home/nickjmk/projects` paths
in historical reports identify the original workspace; use your clone root instead.

```bash
git clone https://github.com/Mookjsi/sirs-reproduction.git
cd sirs-reproduction
python3 reproduction/scripts/bootstrap_sources.py

curl --fail --location \
  https://cloud.r-project.org/src/contrib/Archive/StanHeaders/StanHeaders_2.32.6.tar.gz \
  --output reproduction/environment/downloads/StanHeaders_2.32.6.tar.gz
curl --fail --location \
  https://cloud.r-project.org/src/contrib/Archive/rstan/rstan_2.32.6.tar.gz \
  --output reproduction/environment/downloads/rstan_2.32.6.tar.gz

bash reproduction/scripts/run_r.sh reproduction/scripts/setup_environment.R
```

Prerequisites: Git, Python 3, R, GNU make, a compatible C++ toolchain, curl and sha256sum.
The original environment used R 4.5.3, rstan/StanHeaders 2.32.6; recorded dependency
versions are under `reproduction/environment/`. The installer pins rstan/StanHeaders,
but resolves other dependencies from CRAN, so consult recorded versions for stricter
environment matching. No environment installation or computation runs automatically.

Bootstrap clones the pinned original repository into `perturbation/`, verifies its
tracked-file hashes, recreates the four supplied `raw_data/` aliases from identical
upstream CSVs, and invokes the existing source-preparation script. It never samples,
simulates, plots, installs packages or overwrites an existing differing file.
To review the paper locally, supply your own `perturbation/nature_paper.pdf`; runtime
inference and figure scripts do not require the PDF.

## Manual execution

Read the execution plans before launching work on a shared server:

- [Inference and diagnostics](reproduction/phase3_execution_plan.md)
- [Figures and counterfactuals](reproduction/phase4_execution_plan.md)
- [Panel dependencies](reproduction/figure_dependency_map.md)
- [Comparison criteria](reproduction/figure_comparison_template.md)
- [Original audit](reproduction/audit.md) and [patch log](reproduction/patch_log.md)

For example, prepare original inputs without sampling:

```bash
bash reproduction/scripts/pipeline.sh prepare \
  --out reproduction/user_runs/paper-run-001/data --cpus 1
```

The inference CLI defaults to four chains, 4,000 iterations, 2,000 warmup, original
regional seeds/adaptation, and four CPUs. Changed CPU/sampling settings require an explicit
`--mode non-reproduction` label. Only a user-invoked `run`/`run-all` command samples.
Only explicit counterfactual/figure/PPC commands perform their corresponding computations.

**Fresh-clone cache note:** Phase 2 compiled models are deliberately not distributed.
Omit `--cache reproduction/results/phase2-smoke-20261104/compiled` from inference examples
to compile unchanged original models when needed. Historical smoke scripts/results paths
remain documented as historical artifacts, not bundled scientific results.

The source provides five seasonal fits and three pre/post fits (Honshu, Shikoku, Kyushu).
Main Figure 3 uses seasonal fits; pre/post comparisons belong to Supplementary Figure S8.
Paper/source change-date discrepancies, primary ERA5 provenance gaps and publication
archive equivalence remain documented limitations. No exact reproduction is claimed.

# Phase 4 manual execution plan

**Code implementation only. Codex has not invoked scientific commands, simulations,
plotting, inference or PPCs in this phase.** Only inspection, R/shell parsing and static
checks were performed. The new figure/simulation integration is not runtime-verified.
No running experiment or existing result was changed.

Run these commands yourself from `/home/nickjmk/projects`. Use new output directories;
every command refuses existing outputs. The examples reuse the existing Phase 3 campaign
paths. Do not restart inference just to generate figures. If your fit campaign is elsewhere,
substitute its directory in `FITS` and its exact corresponding prepared directory in `DATA`.

```bash
DATA=reproduction/user_runs/paper-run-001/data
FITS=reproduction/user_runs/paper-run-001/fits
ART=reproduction/user_artifacts/paper-figures-001
```

## 1. Inspect dependencies without numerical/scientific execution

```bash
bash reproduction/scripts/pipeline.sh check-figures --target all \
  --data "$DATA" --fits "$FITS" --out "$ART/dependencies-before-simulation" --cpus 1
```

The checker reads small manifests/input metadata and file hashes, installed-package
metadata and completion markers. It does not source scientific scripts, summarize draws,
simulate or plot. Read `dependencies.csv`: READY means available dependencies only, never
successful convergence. Running fits without COMPLETE are BLOCKED and untouched. Figure 3
and S6/S7 are BLOCKED until their original saved simulations exist. Other figures can be
run as soon as their own required posterior files complete.

## 2. Generate Figure 1 independently of posterior inference

```bash
bash reproduction/scripts/pipeline.sh figure --figure 1 \
  --data "$DATA" --out "$ART/figure1" --cpus 1
```

The command checks the prepared-data input hashes, stages original inputs, and runs the
original loader/figure script. It generates the original main PDF/PNG and S1 PDF with
original normalization, season definitions and trough statistics. No fit or simulation
is needed. No observed values are synthesized to extend the 2024 display axis.

## 3. Run priority Figure 3 counterfactuals, then plot

**Required:** completed original seasonal Honshu, Shikoku and Kyushu fits from Phase 3.
Pre/post fits are not inputs to the published main Figure 3.

```bash
bash reproduction/scripts/pipeline.sh counterfactual --experiment figure3 \
  --data "$DATA" --fits "$FITS" --out "$ART/counterfactual-main" --cpus 1

bash reproduction/scripts/pipeline.sh check-figures --target figure3 \
  --data "$DATA" --fits "$FITS" --simulations "$ART/counterfactual-main" \
  --out "$ART/dependencies-figure3" --cpus 1

bash reproduction/scripts/pipeline.sh figure --figure 3 \
  --data "$DATA" --fits "$FITS" --simulations "$ART/counterfactual-main" \
  --out "$ART/figure3" --cpus 1
```

The first command executes the three original 21×21 grids and original 41×41 interpolation,
using coordinate-wise medians and unchanged `R/simulate_sirs.R`. It does **not** plot.
It saves original-named simulation `.rda` files, all exact call arguments and 53-row state
trajectories, source metadata, 52-week timing summaries, paired peak/CoG metrics, GAM
profiles, clipping counts and hashes **before** a later figure command loads them.
No new epidemic mechanism, stochastic model, parameter fit or prior is introduced.

The figure command verifies that simulation-data and posterior hashes match the selected
fits, then runs the original Figure 3 script. Main 3A is weighted CoG; 3G is a paired
argmax difference. Both independent exports are retained without substituting one statistic
for the other. Display GAM curves use the original finer grid separately from simulations.

## 4. Figures 2 and 4 once all five seasonal fits complete

```bash
bash reproduction/scripts/pipeline.sh figure --figure 2 \
  --data "$DATA" --fits "$FITS" --out "$ART/figure2" --cpus 1

bash reproduction/scripts/pipeline.sh figure --figure 4 \
  --data "$DATA" --fits "$FITS" --out "$ART/figure4" --cpus 1
```

Figure 2 also produces the original S4 temperature and S5 temperature/humidity PDFs.
Figure 4 loads all five fit files as the source does, though only the three main islands
appear in its plot. The original childcare workbook is present and pinned. If absent or
invalid, panels 4A/B are BLOCKED; no observations are reconstructed. The original national
four-category totals and source year/season selection remain unchanged.

Alternatively, after all main dependencies are ready, generate all main figures into a
**new** output directory with `figure --target all` and the same --data, --fits,
--simulations, --out and --cpus arguments. This runs no new simulations automatically.

## 5. Pre/post-shift transmission estimates: original Supplementary Figure S8

**Required:** completed original Honshu, Shikoku and Kyushu prepost fits. These use source
dates and Shikoku's published prior exception. Methods-versus-source dates remain explicit.

```bash
bash reproduction/scripts/pipeline.sh supplement --target s8 \
  --data "$DATA" --fits "$FITS" --out "$ART/s8-prepost" --cpus 1

bash reproduction/scripts/pipeline.sh supplement --target s8-ratios \
  --data "$DATA" --fits "$FITS" --out "$ART/s8-ratios" --cpus 1
```

S8 preserves the source red beta versus blue beta2 plot, case fit, full susceptible curves
and week-26 susceptible estimates. The ratios target invokes `analysis/analysis_beta.R`
and stores the original visible quantile outputs in its log and visible_results.rds.
The Phase 3 `extract` command also exports those quantiles as transmission_change.csv.
No alternate change-point assumption is invented or silently fitted.

## 6. Additional regional counterfactuals and supplementary figures

Use these instead of step 3's counterfactual command if you want all five regional grids
and interpolation in one fresh output. They do not run main figures implicitly.

```bash
bash reproduction/scripts/pipeline.sh counterfactual --experiment all \
  --data "$DATA" --fits "$FITS" --out "$ART/counterfactual-all" --cpus 1

bash reproduction/scripts/pipeline.sh supplement --target all \
  --data "$DATA" --fits "$FITS" --simulations "$ART/counterfactual-all" \
  --out "$ART/supplementary" --cpus 1
```

For individual simulations, --experiment accepts Honshu, Shikoku, Kyushu, Hokkaido,
Ryukyu or interpolate. Individual supplementary targets are s1 through s8 and s8-ratios.
S1/S4/S5 duplicate byproducts of main scripts in separate fresh workspaces; running those
targets again is optional. `supplement --target all` runs available targets and records
BLOCKED ones, such as S2 without optional map packages, in dependencies.csv. A single
blocked target fails before scientific execution. Main `figure --target all` requires
every requested dependency, rather than silently producing incomplete main figures.

Optional map-only environment setup, user-invoked and not run by Codex:

```bash
bash reproduction/scripts/run_r.sh reproduction/scripts/setup_figure_extras.R
```

This installs maps/mapdata/ggfortify and their required dependencies into the existing
private R library. Rerun dependency inspection in a new output directory afterward.
Map execution preloads ggplot2 because the original map script sets its theme before
attaching ggplot2; the plotting expressions and map selection are unchanged.

## Inputs, provenance and output contract

Commands use `--data` (Phase 3 prepared directory), `--fits` (campaign fit root),
`--simulations` (completed Phase 4 counterfactual directory where needed), `--out` and
`--cpus`. Figure/simulation work is serial; --cpus is an upper bound, not a parallelism
request. No MCMC can be launched by any Phase 4 action. There is no background or scheduler
integration and no inference-command auto-execution.

Default acceptance requires original reproduction-mode fits. An explicitly labelled
resource-only/non-reproduction campaign may be read with `--mode non-reproduction`;
the provenance records that label. In all modes, fits need at least four chains, 2,000
post-warmup draws per chain and 2,000 warmup; smoke/short fits are rejected, including
actual loaded stanfit metadata. No synthetic estimates, supplied published numbers or
smoke results are substituted. Fit COMPLETE is necessary, not a convergence guarantee.

Each command writes dependencies.csv and STATUS. Scientific commands additionally record
prepared-data/model/config/fit/source hashes, original fit manifests, available diagnostic
status, command/session/package/code versions, logs and stage workspaces. Every figure
target contains:

- `workspace/`: isolated copy of original code/inputs and required original-named fit and
  simulation files, with the Phase 2 capitalization helper; no original reference PDFs copied.
- `products/`: original generated PDFs/PNGs with original dimensions and filenames.
- `tables/`: original plotting data objects, not manually reconstructed estimates.
- `panels/`: original unrendered g* plot objects for subsequent inspection.
- `visible_results.rds`: original visible statistical outputs and source expressions;
  regression and correlation output is also printed into execution.log.
- smoothing_values.rds when the source defines GAM display values; COMPARISON_PENDING.

Counterfactual outputs include simulation_arrays/ plus original `.rda` under
workspace/simulate_sirs/, simulation_catalog.rds, simulation_hashes.csv and a
SIMULATIONS_COMPLETE marker. No plotting starts in that command. A later figure command
requires the same bundle and posterior-file hashes. Reusing old simulations with newly
fitted posteriors is rejected. All outputs remain separate from Phase 2 and Phase 3 results.

## Failure handling and resources

Do not delete or alter running fits. If a fit is incomplete, wait and rerun dependency
inspection into a fresh output directory. An ambiguous campaign with multiple COMPLETE
attempts for the same pair is rejected instead of selecting a posterior silently.
Normally Phase 3's restart logic creates exactly one completed attempt; alternate scientific
runs should use a separate campaign root. Failed/incomplete figure or simulation outputs
are preserved; rerun with a new --out. Status records and exact errors are in the stage log.

No Phase 4 resource measurements exist. Estimates: one CPU; allow roughly 4–8 GiB RAM for
regional/interpolation simulations and 8–16 GiB for scripts loading all five full stanfit
objects and summary tables. Actual requirements depend on serialized fit sizes. Plan
minutes to tens of minutes per original workflow for summary/GAM/IO and plotting; this is
an unmeasured allowance, not a benchmark. Main Figure 3 is 4,685 trajectories of 53 states;
all-region plus interpolation is 5,567 trajectories. Raw numeric state tapes are modest;
posterior objects, repeated summary calls and staging IO dominate resources.
Staging **copies** the required original-compatible RDA files into each fresh target.
Disk usage can therefore be several times campaign fit-file size (potentially many GB
for all supplements); inspect fit sizes before starting. No files are auto-deleted.
Phase 2's measured compilation and MCMC smoke costs are unrelated to Phase 4 figure runtime.

## Verification boundary

Follow [figure_dependency_map.md](figure_dependency_map.md) for every original panel and
[figure_comparison_template.md](figure_comparison_template.md) for numerical, statistical
and visual comparison criteria. STATUS=COMPLETED means the requested code ran, not that
the paper was reproduced. Review posterior diagnostics, exported tables, all peak/CoG
grids, clipping, source-date/index differences and figures. Font/version/layout differences
remain possible. No exact numerical or graphical reproduction is claimed before user
execution and evidence-based comparison. Stop here; no Phase 5 work is launched.

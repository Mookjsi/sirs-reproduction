# Patch log

## Applied during Phase 1

Only documentation, provenance manifests, and read-only audit evidence were added under
`reproduction/`. No original source, input, prior, model, MCMC setting, or existing result
was edited. No compatibility fixes have been applied. No R preprocessing or inference ran.

## Phase 1 proposals (historical; Phase 2 authorized on 2026-11-04)

| ID | Change in isolated execution copy only | Justification |
|---|---|---|
| C01 | Add missing `R/firstup.R` capitalization helper | Figure labels; no mathematical effect |
| C02 | Delete unused `birth <- filter(japan_birth_island,...)$birth` assignments | Undefined object stops four fit scripts; birth variable never used; model already uses fixed mu |
| C03 | Control working directories and collect outputs into unique run directories | Preserve relative input paths and prevent overwriting author artifacts |
| C04 | If stanc rejects old arrays, translate declaration syntax only | Compiler compatibility; preserve exact density and dimensions |
| C05 | Spell `chains=4` explicitly if required | Avoid reliance on partial argument matching; same number of chains |
| C06 | Sequential chains, controlled thread counts, after resource approval | Shared-server CPU ceiling; no change to iterations, priors or chains; record concurrency deviation |
| C07 | If needed, plotting API/font compatibility only | Record exact version issue and visual effect; no changes to plotted data |

Each implemented fix must record original file hash, exact diff, rationale, test evidence
and resulting hash. Merely proposing a fix does not prove it works.

## Scientific differences: do not treat as compatibility patches

- Kyushu/Shikoku sensitivity break dates differ between published Methods and scripts.
  Preserve source dates initially; resolve archive provenance and seek a separate decision
  before any paper-date branch. Never relabel an edited model as unchanged source.
- Preserve the original season conventions, week-53 averaging, dimensionless GAM amplitude,
  missing first-observation likelihood, Shikoku prior exception, and baseline start dates.
- Missing daily/hourly climate provenance is a documented limitation, not permission to
  generate replacement inputs.

## Applied in Phase 2

User authorized isolated setup, compilation and a bounded smoke test. Original checkout
and pinned `source/475c7dcdadc12987033d332b101f025625074301/` remain unchanged.

- **C01 applied:** added `work/<commit>/R/firstup.R`, a first-letter capitalization helper.
- **C02 applied:** removed exactly four unused birth assignments (three baseline scripts
  and Honshu two-period script). No birth observations were added or substituted.
- **C03 applied:** `scripts/prepare_source.py` creates a pinned snapshot and separate work
  tree; stage scripts use explicit working directories and distinct result files. Guards
  refuse to overwrite completed preprocessing or sampling outputs.
- **Environment:** private `environment/library`, archived rstan and StanHeaders 2.32.6,
  one build job, one BLAS/OpenMP/TBB/Stan thread, process niceness 10. Private Makevars
  uses `-O1 -g0` for C++ to reduce build cost; no system/user R library configuration edited.
- **Smoke-only settings:** one chain, 60 iterations (40 warmup, 20 retained), seed 102,
  adapt_delta 0.90, maximum tree depth 8, explicit valid initialization. The lower tree-depth
  ceiling bounds smoke-test work. These settings are not used for published inference;
  full Honshu settings remain four chains, 4,000 iterations, default half warmup, depth 15.
- **No scientific patches:** change dates, priors, likelihood and SIRS updates preserved.

Exact source diffs: `patches/compatibility.patch`. Before/after SHA-256 values:
`patches/file_hashes.tsv`. The dependency source archives and complete installation log
are retained under `environment/`. Compilation and smoke outcomes are recorded in the
Phase 2 report once their checks finish.

## Phase 2 validation outcomes

- `PREPROCESS_PASS`: original loader ran; independent case aggregation agrees exactly;
  5 × 572 ordered island weeks; no missing processed cells; expected populations.
- `ALL_MODELS_COMPILE_PASS`: four original Stan specifications compiled, unchanged.
  C04 (syntax conversion) and C05 (partial-argument change) were unnecessary and not applied.
- `SMOKE_PASS_EXECUTION_ONLY`: Honshu 20 retained draws; finite expected state/parameter
  dimensions; finite log density/gradient; R/Stan state errors below 1e-6; zero divergences.
- Smoke depth ceiling 8 was hit in 19/20 retained transitions; short-chain R-hat/ESS and
  warmup-window warnings retained. No production convergence claim or compensating full run.
- Compilation metadata emitted a `timedatectl` container bus warning; it did not affect builds.
- See `phase2_report.md` and the run logs for exact commands, versions, timings and diagnostics.
  Full scientific verification remains pending. No Stan prior, likelihood or equation edits.

## Phase 3 implementation-only delivery

No sampling, SIRS/counterfactual simulation, predictive draws, pipeline invocation,
background work or scheduler submission was performed by Codex in this phase. Phase 2
outputs and all original tracked source files remain unchanged.

Added:

- `configs/defaults.R`, `configs/regions.csv`, `configs/README.md`: original defaults and
  eight source-linked region/variant configurations. No invented Hokkaido/Ryukyu prepost fits.
- `scripts/pipeline.sh`, `pipeline.R`, `pipeline_common.R`, `pipeline_actions.R`: explicit
  CLI, original-loader preparation, serial regional orchestration, four-chain defaults,
  isolated logging, hashes, original-named posterior RDA export, guarded outputs and
  between-fit restart. Default random initialization replaces no scientific assumption;
  Phase 2's smoke-specific explicit initializer is not used.
- `diagnostics/posterior.R` and README: extraction, legacy/rank diagnostics, base-R plots,
  and separately invoked NB2 conditional observation PPCs. PPCs are additional diagnostics,
  not replacements for any published computation or generated epidemic trajectories.
- `scripts/check_static.py`: source/configuration comparison and parse-only validation;
  never invokes pipeline actions.
- `phase3_execution_plan.md`: exact user commands, recovery, completion/diagnostic gates,
  measured Phase 2 costs versus unmeasured full-inference planning estimates.
- Updated README and historical plan gate to reflect implementation-only authorization.

Validation is limited to R parsing, shell syntax, source/configuration inspection and file
hash checks. New CLI actions have not been executed. Static validation outcomes are in
`phase3_static_validation.txt`. Runtime validation must be performed by the user using the
execution plan. No Stan changes or new dependencies were required; the existing installed
posterior package supplies rank-normalized diagnostics.

Overrides of chain count, iterations, warmup, seed **or CPU count** now require explicit
`--mode non-reproduction`, as requested. Source date discrepancy, missing primary climate
inputs and publication-archive equivalence remain documented limitations, not patched.

## Phase 4 implementation only

No MCMC, scientific data processing, posterior summaries, SIRS/counterfactual simulations,
PPCs, figure rendering, dependency-CLI invocation, background job or scheduler action was
executed by Codex in this phase. Existing Phase 2/3 results and running experiments were
not modified. Original tracked source and pinned snapshot files remain unchanged.

Added figure catalog/configuration, source adapter, original-counterfactual runners,
figure dispatcher, optional map-dependency installer (not run), static checker, panel
mapping, execution plan, comparison template and directory READMEs. Updated the main README.
The existing pipeline.R gains only Phase 4 dispatch/source definitions; parse_options gains
an optional extra_allowed argument, preserving existing Phase 3 calls and defaults.
No scientific changes were made to existing inference actions or configurations.

Compatibility/execution adaptations, separate from scientific source:

- Stage original code/inputs into a fresh --out workspace, excluding author reference
  figures; copy required original-named Phase 3 RDA files automatically. Nothing is edited
  or linked into the user's fit campaign. A running R process retains its loaded functions;
  no process was signalled or interrupted.
- Reuse the hash-checked Phase 2 firstup.R helper. No additional helper scientific logic.
- Evaluate original parsed expressions in an isolated environment. Redirect source() and
  load() to that environment, retaining load invisibility; reject short/smoke stanfit metadata.
  Visible original regression/quantile output is logged and exported.
- Counterfactual source()/simulator tap records exact arguments and returned states of
  each original call without changing its equations or outputs. Added timing tables are
  verification exports, not replacements for original source CoG/argmax statistics.
- Preload ggplot2 before original map execution because its theme_set precedes its own
  ggplot2 library call. No data, map geometry, axes, colors, smoothing or labels edited.
- Restore nested message-log connections inside the new figure logger; existing Phase 3
  logging code and sampling actions are unchanged.
- Phase 4 dependency checks verify required original source/input hashes per target so
  missing childcare data can be reported as BLOCKED for Figure 4 rather than silently
  reconstructed or hidden by an unrelated-source failure. Legacy Phase 3 source checks
  retain their original full-manifest behavior.

Scientific discrepancies explicitly retained: Figure 3 seasonal versus S8 prepost identity;
Shikoku/Kyushu change dates; observed versus simulated seasons; Ryukyu incidence labels
and unused versus plotted CoG offset; Hokkaido I0 annotation versus trajectory indices;
integer-week simulation versus finer display GAM grids; original fill clipping and repeated
interpolation rows. No new change-point sensitivity experiment was invented.

Static-only results are in phase4_static_validation.txt. Original script hashes and
configs are recorded in the catalog/provenance; runtime artifacts will retain exact code,
model, posterior, data, configuration, package and simulation hashes after user execution.
No numerical or graphical success is claimed in this implementation-only delivery.

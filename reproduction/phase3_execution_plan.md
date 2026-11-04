# Phase 3: user execution plan

**Implementation-only delivery. Codex did not execute these commands or any Phase 3
experiments.** Only source inspection, syntax checks and static configuration/hash checks
were performed. Phase 2 results and original source are preserved. Runtime behavior of the
new orchestration remains untested by execution, as requested.

Run the commands below yourself from `/home/nickjmk/projects`. Choose a new campaign path
instead of `paper-run-001` if it already exists. Nothing is submitted to a scheduler,
backgrounded or automatically started. All eight fits run sequentially by region; at most
four single-thread chains run concurrently inside one fit in reproduction mode.

## 1. Prepare all original data configurations

```bash
bash reproduction/scripts/pipeline.sh prepare \
  --out reproduction/user_runs/paper-run-001/data --cpus 1
```

This runs the original loader in the pinned snapshot, verifies raw/supplied hashes,
independent case aggregation and ordering, then writes eight Stan input lists in
`data/bundle.rds`, preprocessed CSVs, provenance, log, sessionInfo and STATUS.
Expected success: `PREPARE_COMPLETE` in execution.log and STATUS=`COMPLETED`.
No MCMC is part of this command. Missing hourly/daily ERA5 stages remain outside its scope.

## 2. Run the five seasonal fits with original inference defaults

```bash
bash reproduction/scripts/pipeline.sh run-all --variant seasonal \
  --data reproduction/user_runs/paper-run-001/data \
  --out reproduction/user_runs/paper-run-001/fits --cpus 4 \
  --cache reproduction/results/phase2-smoke-20261104/compiled
```

Each region gets `fits/seasonal/<Region>/attempt-001/`. Models are chosen from the
registry, original priors and states are untouched, and the original random initialization
is used. Cache reuse checks the model source. Omit `--cache` to compile from pinned source
instead if the R/platform has changed; do not use a cache from a different machine/runtime.

To run just one region instead of the above, use a separate fresh fit root:

```bash
bash reproduction/scripts/pipeline.sh run --region Honshu --variant seasonal \
  --data reproduction/user_runs/paper-run-001/data \
  --out reproduction/user_runs/honshu-only/fits --cpus 4 \
  --cache reproduction/results/phase2-smoke-20261104/compiled
```

## 3. Run the three source-faithful pre/post fits

```bash
bash reproduction/scripts/pipeline.sh run-all --variant prepost \
  --data reproduction/user_runs/paper-run-001/data \
  --out reproduction/user_runs/paper-run-001/fits --cpus 4 --resume \
  --cache reproduction/results/phase2-smoke-20261104/compiled
```

Here `--resume` permits adding results to the existing campaign root; it does not modify
seasonal results. The three supported configurations are Honshu, Shikoku and Kyushu.
For one command covering all eight instead of steps 2–3, use `run-all --variant all` with
a fresh output root and the same data, CPU and cache arguments.

Paper/code change-date discrepancies remain explicitly documented in configs/README.md.
The source branch is runnable without inventing Hokkaido/Ryukyu prepost assumptions.

## 4. Extract, diagnose and plot one completed fit

```bash
RUN=reproduction/user_runs/paper-run-001/fits/seasonal/Honshu/attempt-001
bash reproduction/scripts/pipeline.sh extract --run "$RUN" --out "$RUN/extract" --cpus 1
bash reproduction/scripts/pipeline.sh diagnose --run "$RUN" --out "$RUN/diagnostics" --cpus 1
bash reproduction/scripts/pipeline.sh plots --run "$RUN" --out "$RUN/plots" --cpus 1
```

Read `diagnostics/quality_checks.txt`, `chain_diagnostics.csv`, `rank_diagnostics.csv` and
the trace/sampler PDFs. A COMPLETE file means sampling produced finite, dimension-checked
draws; it **does not certify convergence or reproduction of the paper**. Convergence remains
`REVIEW_REQUIRED` unless the declared checks pass. Original rstan summary diagnostics are
also retained, including undefined diagnostics on deterministic constants.

## 5. Generate additional conditional observation PPCs (explicit simulation command)

```bash
bash reproduction/scripts/pipeline.sh ppc --run "$RUN" --out "$RUN/ppc" \
  --cpus 1 --draws 200 --seed 102
```

This command draws replicated observations from the original NB2 likelihood only.
It is deliberately separate from inference/extraction and was **not executed by Codex**.
It excludes observation 1 and writes replicate arrays, intervals, discrepancy checks and PDF.

For all completed attempts, you can run postprocessing manually in a foreground shell loop:

```bash
for RUN in reproduction/user_runs/paper-run-001/fits/*/*/attempt-*; do
  test -f "$RUN/COMPLETE" || continue
  bash reproduction/scripts/pipeline.sh extract --run "$RUN" --out "$RUN/extract" --cpus 1 || break
  bash reproduction/scripts/pipeline.sh diagnose --run "$RUN" --out "$RUN/diagnostics" --cpus 1 || break
  bash reproduction/scripts/pipeline.sh plots --run "$RUN" --out "$RUN/plots" --cpus 1 || break
  bash reproduction/scripts/pipeline.sh ppc --run "$RUN" --out "$RUN/ppc" --cpus 1 --draws 200 --seed 102 || break
done
```

Use either the per-fit commands or the loop, not both with the same output directories.
A repeated postprocess command needs a fresh directory (e.g. `diagnostics-v2`).

## Configurable non-reproduction modes

Original defaults: chains=4, iter=4000, warmup=2000, thin=1, cpus=4, depth=15;
seeds/adapt_delta/Nnonpi/model selection are in `configs/regions.csv`.
Any chains/iter/warmup/seed/CPU override requires the explicit label below:

```bash
bash reproduction/scripts/pipeline.sh run --region Honshu --variant seasonal \
  --data reproduction/user_runs/paper-run-001/data \
  --out reproduction/user_runs/serial-nonreproduction/fits \
  --mode non-reproduction --cpus 1 --chains 4 --iter 4000 --warmup 2000 --seed 102 \
  --cache reproduction/results/phase2-smoke-20261104/compiled
```

This example preserves statistical settings but lowers chain concurrency and is labelled
non-reproduction as requested. Smaller iter/warmup/chains values are permitted in this
mode only. No warm starts or smoke initializers are substituted. Warmup must be less than
iter. Region-specific default seeds are preserved unless explicitly overridden.

## Outputs and recovery

Each sampling attempt stores original `model.stan`, exact `standata.rds`, `manifest.rds`/txt,
configuration/source/data hashes, sessionInfo, commands, execution log, warnings, chain CSVs,
`fit.rds`, original-compatible named `.rda`, timing, COMPLETE and STATUS. Index CSVs identify
completed paths. The `.rda` object name matches original plotting scripts; those scripts
must later load these original-compatible files from an isolated figure workflow, not
smoke results. This delivery does not run or automatically generate main Figures 1–4.

- If a region fails, inspect its attempt's STATUS and execution.log. Stop-on-error prevents
  silently skipping a failure and continuing an apparently complete campaign.
- Repeat the same run command with `--resume`: matching completed fits are skipped;
  failed/incomplete fits get a fresh attempt-002, preserving all prior files. Settings and
  prepared-data digest must match completed manifests; otherwise use a new output root.
- Restart is **between fits**, not mid-NUTS: rstan provides no sampler-state checkpoint here.
  Interrupted chain CSVs remain evidence, but no partial fit is silently accepted or merged.
  Failed/unfinished regions rerun all chains. Atomic fit writes prevent accepting partial RDS.
- A `.pipeline-lock` directory prevents two writers to the same campaign. Normal exit/error
  clears it. After a hard kill, inspect its owner.txt PID and independently establish that
  the prior job has exited before manually removing only that stale lock directory.
- No command overwrites successful results or auto-tunes inference after diagnostic failure.
  Correct an environment issue and resume, or create a new, documented non-reproduction run.
- A failed data preparation or postprocessing stage must be rerun into a fresh output path.

## Resource planning: estimates versus measurements

Measured in Phase 2: four serial compilations took 67.2–92.4 seconds each. Honshu smoke
used 60 iterations of one chain at depth cap 8: 7.136 sampler seconds, 11.493 seconds for
the R call. These measurements **cannot predict** full depth-15 convergence or runtime.
No full-run memory/runtime benchmark was performed in Phase 3.

Planning estimates, not measurements: reserve 4 CPU cores and roughly 4–8 GiB RAM per
four-chain fit. With cached models there is no compilation step; compiling from source
is single-job and may need several GiB. Reserve roughly 1–3 GB disk per fit for draws,
CSV, fit.rds and duplicate original-compatible .rda. The basic retained draw array alone
is about 0.20 GB (8,000 × ~3,130 × 8 bytes); processing makes additional copies.
Postprocessing is serial; allow 2–4 GiB RAM, and PPC memory scales with --draws.
For scheduling, allow **1–4 hours per full fit as a conservative unmeasured allowance**,
or 8–32 hours for eight sequential fit slots; actual runtime may be substantially shorter
or longer. The authors' M2 <10-minute/model claim is not a measurement on this server.
Serial non-reproduction CPU mode may increase elapsed time by up to roughly fourfold.
Do not increase resources or launch parallel campaigns without coordinating server usage.

## Completion checks and remaining limits

Successful sampling: COMPLETE present, STATUS=COMPLETED, full expected chain/draw dimensions
and finite draws, original config/model/data provenance recorded. Successful convergence:
review diagnostics/quality_checks.txt and plots, including per-chain BFMI, not just file existence.
Successful scientific reproduction additionally requires later evidence-based comparison
with the paper; none is asserted here.

Unresolved limits: missing daily/hourly ERA5 inputs; unverified publication-archive/commit
equivalence; source-versus-paper sensitivity dates; dependencies other than rstan/StanHeaders
not known to match the authors' full environment. These do not justify changing source
assumptions or inventing missing regional variants. No experiments were executed in this phase.

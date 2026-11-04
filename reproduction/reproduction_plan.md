# Ordered reproduction plan

**Current gate:** Phase 2 setup and smoke tests were explicitly authorized and are complete;
see `phase2_report.md`. The ordered plan below records the original intended workflow.
Phase 3 orchestration is now implemented under a strict code-only request. Only the user
will execute experiments; see `phase3_execution_plan.md`. Codex stops before all sampling,
simulation and scientific verification in this phase.

1. **Freeze provenance.** Preserve the existing checkout. After approval, create an isolated
   copy of tracked source at `475c7dcdadc12987033d332b101f025625074301`, check its manifest,
   and record published PDF and all inputs. Verify the paper's Zenodo v1.0.0 archive against
   this commit before declaring it the exact publication snapshot; avoid changing HEAD.
2. **Resolve discrepancies.** Keep source dates for the primary source-faithful sensitivity
   runs. Establish whether the archived version resolves the Kyushu/Shikoku date reversal.
   If unresolved, present it explicitly; obtain a decision before a separately labelled
   paper-date run. It is not a compatibility fix and must not be silently introduced.
   This does not block baseline models or priority Figure 3.
3. **Prepare the minimal environment.** Project-local library; target rstan 2.32.6, record
   full session/toolchain versions. Install only main-figure dependencies. Pin the resolved
   versions. Match mgcv/plotting versions if recoverable; otherwise report version uncertainty.
   Do not alter other projects or running experiments.
4. **Apply and log compatibility fixes in the isolated copy.** Supply capitalization helper;
   remove unused undefined birth assignments; set working directories and unique output paths.
   Run stanc first; only if necessary translate array declaration syntax without changing
   target density, constraints, priors, likelihood, or state updates. Save exact patches.
5. **Reproduce supplied-data preprocessing.** Execute `script/script_data.R`; compare the
   supplied file pairs by hash and validate merged keys, ordering, 572 rows per island,
   94 collapsed duplicate groups, populations, and no missing/noninteger cases.
   Preserve mean-and-round week-53 behavior. Export Stan inputs and preprocessing tables.
   Start from supplied weekly climate, explicitly documenting missing hourly/daily stages.
6. **Render Figure 1 and run lightweight smoke tests.** Compile original baseline and
   Shikoku models with one compiler job; check finite valid log density on actual data.
   Check the unchanged R simulator against Stan transformed states at a valid fixed parameter
   point (including first-observation conventions). Verify summary column names. Any very
   short one-chain sampling requires an agreed resource budget, gets a separate smoke run
   ID and is discarded for scientific conclusions. Do not lower full-run settings because
   a smoke test passes. Render minimal ggplot/GAM checks before long fits.
7. **Resource approval before full inference.** Propose one island at a time, four chains
   run sequentially (`cores=1`, with documented concurrency-only deviation from upstream 4),
   no nested BLAS/compiler parallelism. Confirm allowed CPU ceiling and scheduling before
   launch. Inspect existing workloads read-only at launch; never stop them. Source README's
   <10-minute/model M2 estimate is not a reliable server runtime prediction. Save logs,
   timings, memory information if available, per-chain draws, run metadata and diagnostics.
8. **Priority inference: Honshu → Kyushu → Shikoku baseline.** Preserve each seed,
   adapt_delta, Nnonpi, four chains, 4,000 iterations with 2,000 warmup, thin=1,
   max_treedepth=15, original initializations and all scientific settings. Diagnose each
   fit before dependent plots. Do not tune away convergence failures silently.
9. **Priority Figure 3.** Execute three regional 21×21 simulations and 41×41 interpolation
   with original posterior medians, GAM, I0 index, and week ordering. Save the full grids,
   paired peak weeks, CoG values and trajectories. Run the original Figure 3 plot in isolation.
   Inspect all corners and the interior, ties, nonfinite values, and display clipping;
   do not infer reproduction from a synthetic forcing example or a maximum shift alone.
10. **Complete main figures.** Fit Hokkaido and Ryukyu with their published intervention
    start exceptions. Produce Figure 2 and Figure 4 with all five artifacts as their scripts
    expect. Keep the national childcare data and coordinate-wise medians unchanged. Export
    observed/fitted timing, beta curves, NPI trajectories, susceptible summaries, regressions
    and childcare correlations. No new hypotheses or alternative models.
11. **Published transmission-change sensitivity.** Run the three original two-period models
    only after resolving/documenting dates and resource approval. Execute `analysis_beta.R`,
    export ratio quantiles and percent changes. These three additional fits are needed for
    that requested verification target, although not for Figures 1–4 themselves. Optional
    Hokkaido-raw and other supplementary plots are outside the minimum eight-fit plan.
12. **Verification, then report.** Compare numeric exports and figures with the published
    captions, text, and available author references. Record R-hat, effective sample sizes,
    divergences, tree-depth hits and E-BFMI per chain. The paper gives qualitative diagnostic
    requirements, not a numeric R-hat cutoff; use R-hat ≤1.01 and bulk/tail ESS ≥400 as
    declared review criteria, flag exceptions, and retain upstream n_eff as well. Require zero
    divergences/depth hits and review E-BFMI (<0.3 flagged). These are verification criteria,
    not changes to inference or claims about achieved convergence.

## Classification rules

- **EXACT:** demonstrated deterministic agreement with an identified author artifact or
  numeric reference at a declared tolerance. Byte equality for inputs alone does not make
  an inferred result exact. Rendering pixels need not match fonts across platforms.
- **STATISTICALLY CONSISTENT:** published numeric summaries agree within documented posterior
  uncertainty and Monte Carlo error, with acceptable diagnostics. Overlapping intervals
  alone are insufficient if they mask major discrepancies.
- **QUALITATIVELY CONSISTENT:** direction/pattern agrees, but precise reference outputs or
  numerical evidence are insufficient for a stronger claim.
- **FAILED:** an attempted result materially disagrees or fails required diagnostics; include evidence.
- **BLOCKED:** computation/reference unavailable or not authorized; specify the blocker.

Do not demand bitwise-identical Stan draws across compiler/R versions. No arbitrary numeric
tolerance for paper-only images: digitize with stated resolution if needed, otherwise classify
only qualitative agreement. Figure 3 code's 12–18-week color limits are presentation settings,
not a substitute for reference numeric peak shifts. Current targets and blockers are in
`comparison.md`.

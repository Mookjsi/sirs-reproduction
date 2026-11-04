# Original deterministic counterfactual runners

`original_counterfactuals.R` defines runners only. Codex has not invoked them.
Use the existing pipeline.sh counterfactual command, then a separate figure command;
see [../phase4_execution_plan.md](../phase4_execution_plan.md).

The original simulation scripts and R/simulate_sirs.R remain unchanged. A transparent
wrapper around the same deterministic calls records arguments and returned state arrays.
It introduces no new equations, parameter settings or RNG. Original .rda objects are
saved, then exact trajectory tapes and both peak-index and case-weighted timing metrics
are exported before plotting. Simulation/posterior/data hashes prevent mismatched reuse.

Supported experiments: figure3 (three main islands plus interpolation), all (five islands
plus interpolation), each original region name, and interpolate. No grids can be silently
reduced or enlarged through CLI options. No pre/post model is substituted into these
seasonal-fit counterfactuals. Source-specific indexing differences are documented in
[../configs/figures/README.md](../configs/figures/README.md).

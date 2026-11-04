# User-invoked posterior utilities

`posterior.R` defines functions only. It does not execute sampling or simulation when read
as part of the CLI. Codex has only parsed this code, not run it on any fit in Phase 3.

- `extract`: standard posterior summaries and temporal/seasonal CSVs; for prepost fits,
  mean(beta2)/mean(beta) posterior quantiles exactly as in the original analysis.
- `diagnose`: rstan legacy Rhat/n_eff for all outputs; rank-normalized R-hat, bulk ESS and
  tail ESS for inferred parameters; per-chain divergences, depth hits and E-BFMI.
  Constants and deterministic states are excluded from the modern convergence gate.
  Gate criteria: at least four chains; R-hat ≤1.01; ESS ≥400; no divergences or depth hits;
  finite E-BFMI ≥0.3. These are declared review criteria, not paper-reported thresholds
  or changes to the model. Failing a gate writes `REVIEW_REQUIRED`; it does not rerun MCMC.
- `plots`: trace plots, energies, tree depths, acceptance and an S0/rho scatter with
  divergences highlighted. Uses base R graphics; no new plotting dependency.
- `ppc`: explicitly requested additional observation-model checks, **not an original
  published analysis or figure**. Reuses posterior expected reported incidence C and phi
  in `rnbinom(mu=C, size=phi)`, the original NB2 likelihood. It neither multiplies by rho
  again nor simulates SIRS dynamics. Observation 1 is excluded because it has no likelihood.
  It stores conditional replicates, pointwise intervals, total/max/zero-fraction tail
  probabilities and a plot. This is an in-sample conditional check, not a forecast or
  posterior validation by itself. `--draws` bounds replicated trajectories; default 200.

Each command takes `--run`, `--out`, `--cpus`; PPC additionally accepts `--draws`, `--seed`.
All postprocessing is serial and uses at most one CPU; larger CPU caps are accepted but
do not increase parallelism. Output directories must be new. Full posteriors remain in
fit.rds and original-named .rda files, so separate extraction does not lose posterior draws.

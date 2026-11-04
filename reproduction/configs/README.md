# Original model registry

`regions.csv` is traced to the fitting script named in each row, at commit
`475c7dcdadc12987033d332b101f025625074301`. `defaults.R` preserves four chains,
4,000 iterations, 2,000 default warmup, thin 1, four CPUs, max_treedepth 15 and
rstan's random initialization with init_r=2. Initial **epidemiological** states remain
inferred S0 and I0 in the unchanged Stan models; the Phase 2 fixed initializer is not reused.

`seasonal` supports all five islands. `prepost` supports Honshu, Shikoku and Kyushu only;
the authors supplied no pre/post model configuration for Hokkaido or Ryukyu, and the
published Methods explicitly excludes them from this sensitivity analysis. A request for
either unsupported pair fails before sampling. `--variant all` runs the eight published
configurations, not ten invented combinations.

Source-date behavior is preserved literally: Honshu/Shikoku switch when
`year + week/52 > 2016.5`; Kyushu switches at `> 2017.5`. Both switch at week 27.
Published Methods instead assigns the later change to Shikoku, not Kyushu. The pipeline
implements **source-faithful** reproduction and does not silently resolve this discrepancy.
No paper-date branch is implemented. Shikoku uses the authors' two `tweak` models, omitting
the independent Normal(1,0.2) NPI prior while retaining the random walk.

Any chains, iterations, warmup, seed or CPU override that differs from these defaults
requires `--mode non-reproduction`, even for a concurrency-only reduction. The manifest
records the exact override. The original inference defaults remain available unchanged.
Other scientific parameters are not exposed as CLI overrides.

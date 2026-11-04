# Source, data, and dependency audit

Audit date: 2026-11-04 (Asia/Seoul). Scope: Phase 1 only.
This is the historical pre-execution audit. Subsequent environment and smoke-test outcomes
are documented in [phase2_report.md](phase2_report.md); original Phase 1 observations follow.

## Evidence and provenance

The actual workspace is `/home/nickjmk/projects`. The paper was located at
`perturbation/nature_paper.pdf`, not at the workspace root. Its full 11-page text,
including Methods (pp. 7–9) and all four main figure captions, was extracted and read.
The published PDF is the scientific reference; local manuscript TeX can differ from it.
PDF SHA-256: `f3c0ef374549a524a2257c46163b6090f542825e5edafb4ac450781c76d1fef9`.

Original repository: `https://github.com/parksw3/perturbation`, local HEAD
`475c7dcdadc12987033d332b101f025625074301` (2025-10-26, commit message `update`).
All 54 tracked files are unchanged relative to HEAD. Only the local paper and `raw_data/`
are untracked in the checkout. There is no tag at HEAD. The paper cites Zenodo v1.0.0,
DOI `10.5281/zenodo.17396085`; equivalence of that archive to local HEAD has **not** been
established. No remote update, download, or source mutation was performed.
`audit_artifacts/source_manifest.tsv` records file hashes and Git blob IDs.

Reviewed the data loader, four Stan specifications, all fitting entrypoints, main
figure scripts, regional counterfactuals, interpolation, and transmission-ratio analysis.
All 29 R files parse with installed R; parsing does not establish runtime compatibility.
No `.rda` posterior or simulation files exist locally in the original checkout. Existing
tracked PDFs are author-provided reference artifacts, not reproduced results.
The sibling `hybrid-neural-sirs/` and earlier synthetic experiments are excluded.

## Available inputs

All four supplied `raw_data/` files are **byte-identical** to corresponding tracked inputs.
This is a file-equivalence finding, not a reproduced scientific result.

| Supplied file | Expected upstream path | Rows | Coverage / schema |
|---|---|---:|---|
| `raw_data/cases.csv` | `data/japan_rsv.csv` | 26,978 | 47 prefectures; 2013–2023; weeks 1–53; cases, lat, long, time, row index |
| `raw_data/population.csv` | `data/japan_pop.csv` | 47 | prefecture, comma-formatted population, island |
| `raw_data/humidity.csv` | `data_processed/data_processed_humidity.csv` | 17,531 | 47 prefectures; 2013 week 1–2020 week 9; key/year/week/humidity, row index |
| `raw_data/temperature.csv` | `data_processed/data_processed_temperature.csv` | 17,531 | same keys; temperature, row index |

SHA-256 values are in `audit_artifacts/input_manifest.tsv`. No blank cells in these CSVs;
case counts are nonnegative integers. Population names match case names after removing
suffixes after `-`. Climate tables have unique prefecture/year/week keys (373 weeks per
prefecture), humidity range 0.00128065–0.02216242 kg/kg and temperature
−10.94359–31.52451 (values consistent with degrees Celsius). Units follow paper/code;
upstream conversion from hourly ERA5 is not supplied.

`data/japan_childcare.xlsx` is present outside `raw_data/`: one sheet, years 2013–2023,
four childcare categories. The figure script sums all four columns per year and uses
2013–2019 national totals. No additional childcare download is necessary.

No additional inputs are needed to start from the authors' supplied weekly data.
However, full upstream raw-data provenance is incomplete: original NIID surveillance
tables and hourly/spatial ERA5 processing code are absent. Daily climate files expected at
`data_climate/era5.q2m.daily.Japan.subregion.201301-202002.csv` and
`data_climate/era5.t2m.daily.Japan.subregion.201301-202002.csv` are missing.
Supplied humidity/temperature files are already weekly processed data despite their
location under `raw_data/`; do not pretend they are daily/hourly ERA5 observations.
Rebuilding those stages from primary sources is BLOCKED; supplied-weekly-data reproduction
can proceed without inventing or fetching replacement data.

## Original preprocessing

`script/script_data.R` removes population suffixes, parses population numbers, sorts
prefectures, and sums population by island. It maps RSV week 53 to week 52, averages
the resulting duplicate weekly counts and rounds using R `round(mean(cases))` (not sum),
retains the first coordinates, merges population, and sums cases by island/year/week.
There are 94 duplicate groups after mapping (47 prefectures in 2015 and 2020), leaving
26,884 prefecture-weeks: exactly 572 for each prefecture. Island ordering in plots is
Hokkaido, Honshu, Shikoku, Kyushu, Ryukyu. Explicit ordering assertions are needed later.
Island populations are 5,140,354; 102,077,895; 3,620,103; 12,640,119; 1,468,318 respectively.

Climate preprocessing scripts gather daily columns, use `lubridate::epiyear/epiweek`,
map week 53 to 52, and average per prefecture/year/week. The loader joins supplied
weekly climate to population, then takes **unweighted** means across prefectures by
island/year/week. Figure 2 subsequently averages all available years by island/week,
including the partial 2020 data; humidity is multiplied by 1000 for g/kg.

Figure 1 uses pre-2020 prefecture maximum cases to normalize the heatmap and caps it at 2.
For non-Ryukyu prefectures it defines seasons week 27–next week 26, computes weighted
mean season week plus 26, and excludes Okinawa from the CoG boxplot. Troughs are minimum
weekly cases divided by population, excluding observations in 2020 for the last season.
Ryukyu uses calendar-year seasons. No preprocessing has been executed in R during this audit.

## Model specification and priors

`stanmodel/sirs_npi.stan` implements the paper's weekly deterministic competing-hazard
SIRS equations, not a continuous ODE or an alternative formulation. FOI is
`beta[week] * (I_previous + omega) / pop * npieff`. Births are `mu*pop`.
Fixed `gamma=1/week`, `mu=1/(80*52)/week`, `N=572`. Initial states are
`S0*pop`, `I0*pop`, `(1-S0-I0)*pop`. Stan constrains all states nonnegative;
S0 and I0 are individually bounded [0,1], with no explicit joint simplex.
Expected reported incidence is `C=StoI*rho`; the first C is zero and the likelihood
starts at observation 2. `cases[i] ~ neg_binomial_2(C[i], phi)` uses variance
`C + C^2/phi`. The R simulator's first case is NA and downstream scripts drop it.

| Quantity | Source prior and constraint |
|---|---|
| 52 weekly beta values | positive; Normal(8,2) **and** cyclic Normal(previous beta,sigma), including beta[1] vs beta[52] |
| sigma | positive; Normal(0,1) |
| post-baseline npi values | positive; Normal(1,0.2) plus sequential Normal(previous,sigma_npi) |
| sigma_npi | positive; Normal(0,0.1) |
| tau (duration of immunity, weeks) | positive; Normal(0,200); transformed `delta=1/tau` |
| omega | positive; Normal(0,200) |
| S0 | [0,1]; Normal(0.08,0.02) |
| I0 | [0,1]; Normal(0,0.001) |
| rho | [0,1]; Normal(0,0.02) |
| phi | positive; Normal(0,10) |

Positive normal parameters implement half-normal support. `sirs_npi_tweak.stan`
is the published Shikoku exception: omit the independent Normal(1,0.2) NPI prior,
retain the random walk (no independent anchor on its first element).
Paper notation uses delta for the intervention multiplier and nu for waning;
code uses npieff/npi for intervention and delta for waning. This is a naming difference.

Two-period sensitivity models `sirs_npi2.stan` and `sirs_npi_tweak2.stan` introduce a
second 52-vector `beta2`, with the same cyclic and Normal(8,2) priors and shared sigma.
The tweak2 version again omits the independent NPI prior. These are published models,
needed for transmission-change estimates, not prerequisites for main Figures 1–4.

## Inference settings

All fitting scripts request `chain=4` (partial argument matching), `iter=4000`,
`cores=4`, `max_treedepth=15`. Warmup is unspecified: rstan default half the iterations,
2,000 per chain; default thin=1 leaves 8,000 total retained samples, consistent with captions.
No explicit initialization or custom chain IDs. Preserve these defaults and record versions.

| Fit | Stan file | Nnonpi / multiplier starts | Seed | adapt_delta |
|---|---|---|---:|---:|
| Honshu baseline | sirs_npi | 364 / 2020 | 102 | 0.90 |
| Kyushu baseline | sirs_npi | 364 / 2020 | 101 | 0.95 |
| Shikoku baseline | sirs_npi_tweak | 364 / 2020 | 104 | 0.99 |
| Hokkaido baseline | sirs_npi | 208 / 2017 | 102 | 0.95 |
| Ryukyu baseline | sirs_npi | 312 / 2019 | 102 | 0.99 |
| Honshu two-period | sirs_npi2 | 364 / 2020 | 102 | 0.90 |
| Kyushu two-period | sirs_npi2 | 364 / 2020 | 102 | 0.99 |
| Shikoku two-period | sirs_npi_tweak2 | 364 / 2020 | 102 | 0.90 |

`stanfit_sirs_hokkaido_npi_raw.R` is an optional unsuccessful-model comparison starting
the multiplier in 2020; not the main Hokkaido fit. Diagnostics requested upstream are
R-hat, n_eff, divergences, maximum-depth hits, and E-BFMI. Comments in source are not
newly observed diagnostics. Paper specifies rstan 2.32.6 but no full environment lock.

## Figure execution graph

| Figure | Exact entrypoint | Required generated artifacts / inputs |
|---|---|---|
| 1 | `figure/figure1.R` | loader plus supplied cases/population (loader also eagerly reads both climate tables); no fits |
| 2 | `figure/figure_comb_sirs_npi.R` | five baseline `stanfit_sirs_*_npi.rda`; weekly climate; posterior medians and 2.5/97.5% quantiles |
| 3 | `figure/figure_comb_sirs_change.R` | Honshu/Shikoku/Kyushu baseline fits; three matching regional simulation `.rda`; `simulate_sirs_interpolate.rda` |
| 4 | `figure/figure_childcare.R` | loads all five baseline fits even though plots use three main islands; childcare workbook; week-26 posterior S summaries |

Figure 2 uses quadratic regression and LOESS of median weekly beta against humidity.
Figure 4 joins national childcare totals to week-26 susceptible estimates for 2013–2019,
uses median estimates in regressions, posterior intervals as error bars, and `cor.test`.
`analysis/analysis_beta.R` computes posterior quantiles of mean(beta2)/mean(beta) for
the three two-period fits; subtract 1 and multiply by 100 to compare percent changes.

Figure 3A: each main island uses a 21×21 grid: S0 linearly 0.078–0.105,
I0 log-spaced 1e-4–3e-3. Other values are coordinate-wise posterior medians (not a joint
posterior draw). `week=c(25:52,1:25)`, tmax=53; drop first case, analyze weeks 26–25.
CoG is `sum(cases*(1:52))/sum(cases)+26`; the fit-state overlay selects week 25.
Figure 3B fixes I0 at grid element 9 and selects even S0 indices 2,4,…,20.
Figure 3C–G uses cyclic cubic GAMs `mgcv::gam(beta~s(week,bs="cc"))` on Honshu/Kyushu
median beta, normalized by mean then amplitude. The simulation uses predictions at integer
weeks. A 41×41 grid spans interpolation 0–1 and amplitudes between the two islands.
Use Honshu population/other median parameters, the same I0 index 9, and paired S0
0.078/0.105. Peak shift is `which.max(low_S_cases)-which.max(high_S_cases)` (first
maximum on ties). There are 1,681 pairs = 3,362 trajectories, plus 1,323 regional trajectories.
The interpolation output repeats scalar shift metrics across 52 rows per pair; deduplicate
only for comparison exports, preserve original calculation. Its `shift_trans` auxiliary
metric is not the Figure 3G case peak shift. Display curves use a finer 0.1-week GAM grid,
so their displayed amplitudes are not numerically identical to simulation-grid amplitudes.

## Dependencies and execution problems

Installed: R 4.5.3, mgcv 1.9-4, g++, make. Missing: rstan, StanHeaders, Rcpp,
RcppEigen, BH, tidyr, dplyr, ggplot2, egg, readxl, gridExtra, lubridate.
Compiler existence is not proof a Stan model compiles. No compilation or sampling was run.
The old Stan array syntax (`int week[N]`, `real beta[52]`) may require syntax-only
translation with the selected modern compiler; confirm with stanc before changing it.
Font availability and ggplot2 compatibility require later rendering checks.

| Issue | Evidence / consequence | Proposed handling after approval |
|---|---|---|
| Missing `R/firstup.R` | sourced by Figures 2–4 and sensitivity plots | compatibility-only helper for first-letter capitalization in isolated copy |
| Undefined `japan_birth_island` | unused assignment in Honshu/Ryukyu/Shikoku baseline and Honshu two-period fit scripts; loader never defines it | remove unused assignment only; do not invent birth data |
| Relative paths and overwrites | scripts source/read/load `../...`, save into current directory | mirrored run directory with fixed cwd, unique output collection |
| Missing daily ERA5 inputs | both climate-processing scripts reference absent `data_climate/` | use identical supplied weekly tables; report raw provenance limit |
| Paper/code sensitivity dates disagree | paper: Honshu/Kyushu 2016 week 26, Shikoku 2017 week 26; source: Honshu/Shikoku `year+week/52>2016.5`, Kyushu `>2017.5` | preserve source branch; no silent date edits; resolve against archive before any paper-date branch |
| Off-by-one date interpretation | strict `>` switches at week 27, not week 26 | record literal source behavior |
| Season conventions differ by analysis | Fig 1 uses weeks 27–26; Fig 3 simulates 26–25 and overlays week-25 state; Fig 4 selects week 26 | preserve original each; report discrepancy, do not unify |
| Caption says 2013–2024 | available RSV observations end 2023 week 52; plot axis extends into 2024 | do not fetch or invent 2024 data |
| Notation/normalization ambiguity | Methods amplitude prose uses beta scale; source normalizes beta by its mean first | preserve dimensionless source amplitude; label interpretation |
| Numeric column indexing | summary columns 4/6/8 assume default 2.5/50/97.5 percentiles | assert names later; do not assume arbitrary summary layouts |
| Presentation clipping | Figure 3G fill limits 12–18 and other plot axis limits may hide values | export full numeric arrays and clipping counts alongside original plot |

The published paper correctly identifies Honshu/Kyushu interpolation; local manuscript
TeX contains a Shikoku reference in that passage. Use the published PDF, not that wording.
No scientific discrepancies have been patched during Phase 1.

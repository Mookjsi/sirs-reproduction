# Published panel → source → input mapping

All script paths below are relative to the pinned original checkout. `g*` names identify
the original plot objects; they are not reimplemented plots. Source commit:
`475c7dcdadc12987033d332b101f025625074301`. Published PDF captions/Methods take precedence
for figure identity; original scripts determine the actual calculations.

Every command requires the Phase 3 prepared `data/bundle.rds`. Staging checks the original
cases, population and weekly climate inputs against its recorded hashes, then reruns the
unchanged original loader in a fresh workspace. Figure 1 is posterior-independent, although
the loader eagerly requires both supplied climate CSVs.

## Main figures

| Panel | Original script and object | Exact data/posterior dependencies and convention |
|---|---|---|
| 1A | `figure/figure1.R`: g1 | `data/japan_rsv.csv`, `data/japan_pop.csv`; 47 prefectures; divide by pre-2020 maximum, cap at 2; latitude order |
| 1B | same: g2 | Original `japan_rsv_summ`; case-weighted CoG, weeks 27–26; +26; 46 prefectures excluding Okinawa |
| 1C | same: g3 | Original trough/pop; all 47; omit 2020 observations in final season minimum; Ryukyu calendar years |
| 1D | same: g4 | Original case aggregation by five islands, 2013–2023; display axis extends into 2024 without adding observations |
| 2A | `figure/figure_comb_sirs_npi.R`: g1 | Five seasonal `stanfit_sirs_<region>_npi.rda`; observed cases, posterior C median and 95% credible interval |
| 2B | same: g2 | Five 52-week beta medians and 2.5/97.5% quantiles |
| 2C | same: g3 | beta plus `data_processed/data_processed_humidity.csv`; unweighted prefecture means, all available years incl. partial 2020; ×1000 g/kg; LOESS and quadratic lm intervals |
| 2D | same: g4 | Five posterior npieff medians/intervals; Hokkaido starts varying 2017, Ryukyu 2019, others 2020 |
| 2E | same: g5 | Five posterior S/pop medians/intervals |
| 3A | `figure/figure_comb_sirs_change.R`: g1 | Honshu/Shikoku/Kyushu seasonal fits and `simulate_sirs_<region>.rda`; 21×21 S0/I0 grids; weighted CoG +26; overlay posterior states at week 25 in 2013–2019 |
| 3B | same: g3 | Same original simulation tables; fixed I0 element 9; S0 elements 2,4,…,20; source week-factor order |
| 3C | same: g4 | Honshu median beta cyclic GAM, 0.1-week display prediction; normalize by mean then amplitude |
| 3D | same: g5 | Honshu seasonal shape with Kyushu display amplitude; gray original Honshu reference |
| 3E | same: g6 | Kyushu shape with Honshu display amplitude; gray Honshu reference |
| 3F | same: g7 | Kyushu shape/amplitude; gray Honshu reference |
| 3G | same: g8 | `simulate_sirs_interpolate.rda`; 41×41 shape/amplitude grid, Honshu medians for remaining parameters, S0 .078/.105; difference in first maximum-incidence indices; original fill limits 12–18 preserved |
| 4A | `figure/figure_childcare.R`: g1 | Loader, all five seasonal files as loaded by source, `data/japan_childcare.xlsx`; plot three main islands' week-26 S/pop for 2013–2019 versus four-category national childcare totals |
| 4B | same: g2 | Same points, posterior error bars and original linear regression; national totals, not invented island observations |

**Figure 3 is not the pre/post-transmission fit figure.** The user-requested pre/post
comparison belongs to S8; both workflows are supported without relabelling the paper.

## Counterfactual sources

| Experiment | Original entrypoint | Required fit files | Original saved object |
|---|---|---|---|
| Honshu | `simulate_sirs/simulate_sirs_honshu.R` | Honshu seasonal | simulate_sirs_honshu |
| Shikoku | `simulate_sirs/simulate_sirs_shikoku.R` | Shikoku seasonal | simulate_sirs_shikoku |
| Kyushu | `simulate_sirs/simulate_sirs_kyushu.R` | Kyushu seasonal | simulate_sirs_kyushu |
| Hokkaido | `simulate_sirs/simulate_sirs_hokkaido.R` | Hokkaido seasonal | simulate_sirs_hokkaido |
| Ryukyu | `simulate_sirs/simulate_sirs_ryukyu.R` | Ryukyu seasonal | simulate_sirs_ryukyu |
| interpolate | `simulate_sirs/simulate_sirs_interpolate.R` | Honshu and Kyushu seasonal | simulate_sirs_interpolate |

All source `R/simulate_sirs.R` unchanged. Regional grids produce 441 × 52 incidence rows.
Interpolation produces 1,681 paired simulations (3,362 trajectories); the original saved
table repeats scalar shift metrics across 52 rows per pair. Full state/argument tapes are
an observational export around the same function calls; no simulator equations are rewritten.

## Supplementary analyses

| Target/panels | Original script/object | Inputs and current implementation status |
|---|---|---|
| S1 | `figure1.R`: g5 | Original stratified CoG; generated as a Figure 1 byproduct; no fits |
| S2 | `figure_map.R`: g1 | Original world2 Japan map; requires maps, mapdata, ggfortify. Mapping dependencies were not installed in Phase 2; checker marks BLOCKED if still missing |
| S3 | `figure_joint_climate.R`: g1 | All five seasonal fits and weekly humidity; original pooled GAM (260 weekly beta/humidity points) |
| S4 | `figure_comb_sirs_npi.R`: g3a | All five seasonal fits, temperature; original LOESS/quadratic fits; Figure 2 byproduct |
| S5 | same: g3b | Weekly temperature/humidity comparison; Figure 2 byproduct |
| S6A/B | `figure_ryukyu_sirs_change.R`: g1/g2 | Ryukyu seasonal + Ryukyu grid; plotted CoG no +26; January-state overlay; source indexing discrepancy retained |
| S7A/B | `figure_hokkaido_sirs_change.R`: g1/g3 | Hokkaido seasonal + its narrower original grid; annotation I0 index 9 versus trajectory index 12 retained |
| S8A/B/C/D | `figure_comb_sirs_npi2.R`: g1/g2/g3/g4 | Three prepost fits: cases; red beta/blue beta2; full S/pop; week-26 S/pop |
| S8 ratios | `analysis/analysis_beta.R` | Same three prepost fits; posterior quantiles of mean(beta2)/mean(beta); original visible quantile results retained |
| Tables S1/S2 support | `figure_comb_sirs_npi.R`: four visible lapply regressions/correlations | Original code prints correlation, bivariate/univariate quadratic regression summaries; stored in logs and visible_results.rds; raw beta/climate tables exported |

No original alternate-change-date experiment script is supplied. Source dates are preserved:
Honshu/Shikoku `>2016.5`, Kyushu `>2017.5`, all at week 27. Methods assigns the later
date to Shikoku. This discrepancy remains unresolved; no new sensitivity experiment is added.

## Missing inputs and runtime gates

Childcare workbook is present: one sheet, years 2013–2023, four childcare categories.
Its audited hash is pinned. Figure 4A/B become BLOCKED if it is absent or mismatched.
No missing childcare observations are invented. The map's optional packages are the only
known supplementary environment gap; no new packages have been installed in Phase 4.

Completed Phase 3 posteriors are selected automatically from `<fits>/<variant>/<region>/attempt-*`.
Exactly one COMPLETE attempt is required per pair; incomplete/running fits are reported,
not read. Full settings and actual loaded stanfit metadata reject smoke/short fits, even in
explicit non-reproduction mode. Default source-faithful mode requires the original manifest.
Diagnostics are recorded as available or NOT_CHECKED; READY never means convergence passed.
Saved counterfactuals must match the selected fit-file hashes and prepared-data digest.

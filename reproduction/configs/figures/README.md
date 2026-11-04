# Figure and simulation configuration

`targets.csv` maps main/supplementary outputs directly to original scripts, required
regions/variants, simulations, packages and product names. It does not replace plotting
transformations with new implementations. `counterfactuals.R` is descriptive validation
metadata; the original scripts, not duplicated grid-construction logic, create all grids.

Main Figure 3 uses the **seasonal** fits, not the pre/post model. Pre/post beta estimates
are Supplementary Figure S8 and `s8-ratios`. A different assignment would not reproduce
the published source. No source or paper change dates have been edited.

All counterfactuals use coordinate-wise posterior medians from rstan summary column 6,
the original simulator, tmax=53 and 52 incidences after dropping the initial NA.
Main grids are 21×21; interpolation is 41×41 with two trajectories at each point.
Figure 3A displays case-weighted mean timing (CoG); Figure 3G displays the difference
between the first maximum-incidence indices. They are not interchangeable.

Original indexing differences are preserved explicitly:

- Observed Figure 1 season: weeks 27–next 26, plus 26 for CoG; Ryukyu calendar year.
- Main/Hokkaido simulations: initial state at week 25, incidence labels 26–next 25.
- Ryukyu: simulator `week=c(1:52,1)`, while saved incidences after dropping row 1 are
  labelled `1:52` by the source. This one-week labelling discrepancy is retained.
  The unused `cog` variable inside its simulation script adds 26, while its **plotted**
  CoG does not. `source_plot_cog` in supplemental metric exports follows the figure.
- Hokkaido: original Figure S7A annotation uses I0 index 9, while S7B uses index 12.
  The caption implies agreement; neither source selection is silently changed.
- Figure 3B uses I0 index 9 and even S0 indices 2,4,…,20; Ryukyu uses I0 index 12.
- GAMs use `s(week,bs="cc")`; simulation predictions use integer weeks; display curves
  use 0.1-week spacing and recompute display amplitudes. Both grids are preserved.

No source counterfactual specifies a random seed. No stochastic simulator is invoked.
Actual fit seeds and settings are recorded from Phase 3 manifests. Source float, grid,
normalization, smoothing, NPI, importation and waning definitions remain unchanged.

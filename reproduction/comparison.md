# Published targets and comparison status

Scientific target inventory. Phase 2 execution passed (see `phase2_report.md`), but smoke
outputs are excluded from these comparisons. **No Phase 3 comparisons have been performed and no scientific
result is claimed reproduced.** BLOCKED below means execution is awaiting approval and
full-inference posteriors; it is not a finding that the author's analysis failed.

| Result | Published target / reference | Current classification and evidence |
|---|---|---|
| Island RSV timing / Fig 1 | Winter-to-fall shift 2016–2017 in main islands; Ryukyu summer; Hokkaido more persistent. Paper Fig 1 p.2; author `figure/figure1.pdf` available | BLOCKED: supplied observations audited but original aggregation and plot not executed |
| Seasonal transmission / Fig 2 | Semiannual beta in Honshu, Shikoku, Kyushu, Ryukyu; Hokkaido exception; humidity/temperature associations. Paper Fig 2 p.3 | BLOCKED: five baseline posteriors absent |
| COVID multiplier and susceptibility / Fig 2 | 2020 transmission reductions; susceptible accumulation and rebound; Hokkaido multiplier from 2017, Ryukyu from 2019 | BLOCKED: five baseline posteriors absent |
| Fig 3A/B | Increasing S0 shifts CoG/trajectory in original three-island grids; overlay 2013–2019 posterior states | BLOCKED: original posterior-dependent grids not run |
| Fig 3C–G counterfactuals | Honshu/Kyushu shape/amplitude interpolation; S0 0.078→0.105; larger amplitude and wider trough yield larger peak-timing shift. Paper Fig 3 p.5 | BLOCKED: no original-fit interpolation outputs or numeric publication grid; source fill scale 12–18 weeks is not measured evidence |
| Transmission-change sensitivity | Honshu +23% [19,27], Kyushu +16% [13,18], Shikoku +14% [7,20]; paper Results p.4 (third island inferred from three-island context) | BLOCKED: three two-period fits absent; Kyushu/Shikoku source dates disagree with Methods |
| Convergence | Paper: low R-hat, high ESS, no divergences/depth exceedances; 8,000 retained draws in captions | BLOCKED: source comments are historical notes, not diagnostic evidence from reproduction |
| Fig 4 childcare association | Honshu r=0.977 [0.847,0.997]; Shikoku 0.943 [0.653,0.992]; Kyushu 0.802 [0.124,0.970] | BLOCKED: workbook present; posterior week-26 S estimates missing |

After approval, add run IDs, file links, numeric differences, tolerances, uncertainty and
diagnostics before changing any classification. Keep input byte-equivalence evidence in
the audit, separate from scientific-result classifications. Earlier synthetic experiments
and sibling alternative inference workflows provide no evidence for these targets.

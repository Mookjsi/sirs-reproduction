# Figure comparison record — fill after manual execution

**All results currently NOT EXECUTED / NOT VERIFIED in Phase 4.** This is a template,
not a reproduction claim. Record the exact fit attempt(s), source/config/model/data hashes,
R/package versions, diagnostics and figure/simulation directories before comparing anything.

| Item | Run ID / evidence |
|---|---|
| Source commit and publication archive equivalence | |
| Data bundle hash | |
| Seasonal and prepost fit attempts / hashes | |
| Convergence checks and trace plots | |
| Counterfactual input/array hashes | |
| Figure product names and hashes | |
| Display/font/version differences | |

| Panel(s) | Required checks | Reproduced value/evidence | Classification |
|---|---|---|---|
| 1A | 47 prefectures, ordering, pre-2020 normalization and cap 2; 2013–2023 data despite 2024 axis | | |
| 1B | 46 prefectures excluding Okinawa; original weeks 27–26 and CoG +26; 2013–2019 season summaries | | |
| 1C | Minimum/pop; 47 prefectures; exclude 2020 observations from last-season minimum | | |
| 1D | Five original island case series; original duplicate-week mean/round aggregation | | |
| 2A | Observed/fitted epidemic timing, posterior C medians/95% intervals; first C=0 convention retained | | |
| 2B | 52-week beta medians/intervals; semiannual shape in four islands, Hokkaido exception | | |
| 2C | 52 beta/humidity points per island; humidity g/kg; exact original mean weights, LOESS/quadratic fits and bands | | |
| 2D/E | NPI starts by island, posterior intervals, susceptible fractions and time ordering | | |
| 3A | Three 441-point original grids; CoG computed with case weights, not argmax; week-25 overlays | | |
| 3B | Fixed I0 grid index 9; ten even S0 choices; full 52-week incidence arrays | | |
| 3C–F | Original cyclic GAM, normalization and interpolation corner shapes; 0.1-week display grid versus integer simulation grid | | |
| 3G | All 1,681 pairs; original S0 .078/.105; paired first-maximum indices; direction/sign of shifts; also inspect CoG shifts separately | | |
| 3G clipping | Full numeric peak-shift grid and counts outside original 12–18 fill range; never use color scale as numeric evidence | | |
| 4A/B | Four-category workbook totals, national versus island distinction, week-26 S/pop, 2013–2019 joins, original bands/linear fit | | |
| S6/S7 | Source-specific grids/indexing; Ryukyu labelling and Hokkaido I0 annotation discrepancy explicitly reported | | |
| S8 | Source change dates retained; red beta/blue beta2 and uncertainty, incidence/S panels, posterior transmission ratios | | |

Published targets to compare after execution (not values to insert into plots): childcare
correlations Honshu .977 [.847,.997], Shikoku .943 [.653,.992], Kyushu .802 [.124,.970];
transmission increases Honshu 23% [19,27], Kyushu 16% [13,18], Shikoku 14% [7,20].
Reference: published paper Results pp. 4–5 and figure captions. A difference may reflect
the documented date discrepancy, fit diagnostics, source/archive or environment versions;
do not change a model or observation silently to improve agreement.

Classification rules: EXACT requires demonstrated deterministic agreement with identified
reference arrays and a declared tolerance; STATISTICALLY CONSISTENT requires documented
uncertainty/Monte Carlo evidence and acceptable diagnostics; QUALITATIVELY CONSISTENT is
limited to visual/directional agreement; FAILED requires an attempted mismatch/error;
BLOCKED identifies a missing dependency. Keep NOT EXECUTED until a user run exists.
The paper supplies no machine-readable Figure 3 numeric reference grid here. Do not claim
exact numeric agreement from the 12–18 color limits or from similar-looking curves alone.

Save the original tables/panel objects and generated PDFs/PNGs. Inspect regression output,
not just successful rendering. Font, glyph, antialiasing or ggplot2 layout differences can
prevent pixel-identical output without changing the original computed values; report both.

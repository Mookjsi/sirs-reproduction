# Descriptive validation metadata only; the original scripts construct the actual grids.
counterfactual_reference <- list(
  main=list(regions=c("Honshu","Shikoku","Kyushu"),S0=c(.078,.105),
            I0=c(1e-4,3e-3),grid=c(21L,21L),week=c(25:52,1:25),tmax=53L,
            output_weeks=c(26:52,1:25),cog_offset=26,selected_I0_index=9L),
  Hokkaido=list(S0=c(.078,.09),I0=c(3e-4,3e-3),grid=c(21L,21L),
                week=c(25:52,1:25),tmax=53L,cog_offset=26,
                annotation_I0_index=9L,trajectory_I0_index=12L),
  Ryukyu=list(S0=c(.078,.105),I0=c(1e-4,3e-3),grid=c(21L,21L),
              week=c(1:52,1),tmax=53L,source_output_weeks=1:52,cog_offset=0,
              selected_I0_index=12L),
  interpolate=list(shape=c("Honshu","Kyushu"),shape_grid=41L,amplitude_grid=41L,
                   S0_pair=c(.078,.105),I0_index=9L,tmax=53L,
                   smoother="mgcv::gam(beta ~ s(week, bs='cc'))",
                   simulation_prediction_step=1,display_prediction_step=.1,
                   summary="coordinate-wise posterior median"))

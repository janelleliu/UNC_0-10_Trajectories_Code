# 01_gradient_heatmap_generation

This folder contains the `Gradient0_*` and `Gradient1_*` scripts copied from the original `codes/` directory.

These scripts estimate functional gradients from FC matrices, align gradients to reference solutions, and write gradient maps, gradient-derived heatmaps, and summary plots. This stage precedes the broader heatmap-feature and harmonization stage in the reviewer-facing workflow.

Recommended review order:

1. `Gradient0_0_Generate_Gradient_1Ds_mean_twinPick_Normal_ref.py`: generate the mean/reference gradient solution.
2. `Gradient0_1_Generate_Gradient_heatmaps_mean_twinPick_Normal.m`: generate gradient heatmaps from the reference solution.
3. `Gradient0_2_MeanHeatmaps_Gradients_Plot_twinPick_Normal.m`: plot mean heatmaps and gradient summaries.
4. `Gradient1_0_*`, `Gradient1_1_*`, and `Gradient1_2_*`: generate and align subject-level or all-sample gradient outputs.

The scripts retain the original analysis logic and may require local path edits before use on approved study data.

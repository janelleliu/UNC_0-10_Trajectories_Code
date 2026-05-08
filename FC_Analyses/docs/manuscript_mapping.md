# Manuscript-to-code mapping

This document maps the reorganized code folders to the manuscript analyses. The manuscript describes the code functionality primarily in the Methods section, with additional details in the Supplementary Methods/Results and figure-specific descriptions.

## Mapping table

| Code location | Analysis role | Manuscript location |
| --- | --- | --- |
| `code/00_preprocessing/` | Template-space support, structural/T1 collection, and preprocessing support used before FC-derived analyses. | Methods: imaging preprocessing and template-space alignment. |
| `code/01_gradient_heatmap_generation/` | Functional gradient estimation from FC matrices, reference alignment, gradient heatmap generation, gradient component summaries, and visualization outputs. | Methods: functional connectivity gradients; Results and figures describing developmental gradient organization. |
| `code/02_heatmap_features_harmonization/` | Heatmap-derived feature generation, ROI/network summaries, ComBat harmonization where applicable, scanner/covariate adjustment, group comparisons, regression analyses, and partial correlations. | Methods: feature construction, harmonization, statistical analyses; Results/Supplementary Results for group and network/ROI summaries. |
| `code/03_mfpca_trajectories/` | Longitudinal feature table construction, spline-based mSFPCA/mFPCA trajectory estimation/reconstruction, developmental trajectory summaries, and group/regression statistics. | Methods: longitudinal trajectory modeling; Results describing functional brain growth trajectories across ages. |
| `code/04_cca_behavior/` | Brain-behavior matrix construction, CCA/PLS descriptive and predictive models, latent projection plots, and bubble heatmap summaries. | Methods: brain-behavior association analyses; Results/Supplementary Results for CCA/PLS findings. |
| `code/05_bag_analysis/` | Brain age gap analyses: deep learning brain-age prediction from early-life FC heatmaps/features, BAG calculation as predicted age minus chronological age, risk-group deviation tests, and classification analyses. | Methods/Results for functional brain age prediction and BAG analyses. |
| `demo/` | Simulated CCA demonstration using compact brain-feature, behavior, and covariate tables. | Not used for manuscript results; included to satisfy software demo requirements without simplifying the spline-based mSFPCA workflow. |

## Notes for reviewers

- The folder numbering follows the intended review sequence of the manuscript/supplement analyses: preprocessing, gradient/heatmap generation, heatmap-derived features and harmonization, spline-based mSFPCA trajectories, CCA, and BAG.
- The included runnable demo is intentionally limited to CCA input/output mechanics using simulated data.
- Gradient, ComBat, and mSFPCA analyses should be reviewed in the original scripts because simplified simulated versions would not reproduce the manuscript methods.
- The full manuscript analyses require controlled-access cohort data and local path configuration.
- Reorganized source scripts preserve the original analysis logic; folder names were added only to make the submission easier to inspect.
- BAG analyses are organized under `code/05_bag_analysis/`.

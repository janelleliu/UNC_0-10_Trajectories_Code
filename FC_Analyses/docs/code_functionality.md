# Code functionality and pseudocode

This document summarizes the source code included in `codes_reorg/code/`. The scripts are reorganized copies of the original analysis code and retain the original analysis logic.

## 00_preprocessing

Representative file:

- `code/00_preprocessing/Collect_T1_2yrspace.m`

Purpose:

- Collect and align structural/template-space resources used by later functional connectivity and heatmap analyses.

Pseudocode:

```text
for each subject or template resource:
    identify the source image/data file
    transform or collect the file in the common 2-year template space
    save the aligned or indexed output for later FC/heatmap analyses
```

## 01_gradient_heatmap_generation

Representative files:

- `Gradient0_0_Generate_Gradient_1Ds_mean_twinPick_Normal_ref.py`
- `Gradient0_1_Generate_Gradient_heatmaps_mean_twinPick_Normal.m`
- `Gradient0_2_MeanHeatmaps_Gradients_Plot_twinPick_Normal.m`
- `Gradient1_0_Generate_Gradient_1Ds_all_NoScale.py`
- `Gradient1_1_Generate_Gradient_heatmaps_all.m`
- `Gradient1_2_Mean_Heatmaps_Gradients_Plot_twinPick_Normal_Align.m`

Purpose:

- Estimate functional gradients from FC matrices.
- Generate gradient-derived heatmaps and summaries.
- Align age-specific or subject-level gradients to a reference gradient space.
- Save gradient maps, eigenvalue/variance summaries, and visualization outputs.

Pseudocode:

```text
load mean or subject-level FC matrices
replace diagonal values with finite constants where needed
fit diffusion-map gradients with BrainSpace
align gradients to a reference gradient solution using Procrustes alignment
write gradient components, aligned gradients, lambdas, variance, and range summaries
plot eigenvalue, gradient-variance, and gradient-derived heatmap summaries
```

Key Python dependency:

- `brainspace`

## 02_heatmap_features_harmonization

Representative files:

- `Heatmap2_0*.py`
- `Heatmap2_1*.m`
- `Heatmap2_2*.m`
- `Heatmap2_3*.m` through `Heatmap2_8*.m`

Purpose:

- Generate and summarize heatmap-derived ROI, network, and FC-derived features.
- Harmonize scanner/batch effects using ComBat where applicable while preserving biological covariates such as age, sex, or gestational age at scan.
- Create harmonized outputs, group/regression summaries, and partial-correlation plots.

Pseudocode:

```text
load subject lists for each age group
load heatmap, ROI, or FC-derived measures for each subject
assemble subject-by-feature data matrices
load covariates such as scanner, sex, and gestational age
apply ComBat harmonization where required
write harmonized data matrices
summarize data by functional networks or ROIs
generate bar plots, heatmaps, regression summaries, and partial correlations
```

Key Python dependencies:

- `neuroCombat`
- `nibabel`
- `numpy`
- `pandas`

## 03_mfpca_trajectories

Representative files:

- `MSFPCA3_0_Make_mFPCA_tables_twinPick_All*.m`
- `MSFPCA3_1_Make_combine_dataframes*.m`
- `MSFPCA3_3_Reconstruct*.m`
- `MSFPCA3_4*.m`, `MSFPCA3_5*.m`, `MSFPCA3_6*.m`

Purpose:

- Convert age-specific network/ROI/gradient summaries into longitudinal data tables.
- Estimate or reconstruct developmental trajectories using spline-based mSFPCA/mFPCA analyses.
- Test group differences and associations with trajectory-derived measures.

Pseudocode:

```text
for each FC, graph, network, ROI, or gradient measure:
    load age-specific subject-level summaries
    combine age-specific data into longitudinal tables
    estimate smooth mean trajectories and subject-specific deviations with spline-based functional models
    reconstruct trajectories from functional principal components
    summarize trajectories by group or condition
    run regression or partial-correlation tests for developmental associations
    save tables, figures, and statistical summaries
```

## 04_cca_behavior

Representative files:

- `CCA4_0_Make_combine_dataframes*.m`
- `CCA4_1_UNC_Tra_Desc.m`
- `CCA4_1_UNC_Tra_Pred.m`
- `CCA4_2_UNC_Tra_main_loop.m`
- `CCA4_3_UNC_Tra_main_results_BubbleHeatmaps.m`
- `UNC_Tra_Desc_REF.m`

Purpose:

- Build CCA/PLS input matrices from brain trajectory measures and behavioral variables.
- Run descriptive and predictive CCA/PLS analyses.
- Summarize latent variable projections, weights, and significance estimates.

Pseudocode:

```text
load trajectory-derived brain variables for each feature level
load behavioral outcomes and covariates
build X brain-feature matrix and Y behavior matrix
write X/Y labels and data matrices
configure CCA/PLS Toolkit settings
optionally impute, z-score, and deconfound data
run CCA or predictive CCA/PLS framework
save latent projections, weights, and permutation-based summaries
plot brain-behavior association figures and bubble heatmaps
```

External dependency:

- CCA/PLS Toolkit and its required MATLAB path setup.

## 05_bag_analysis

This folder contains code for the manuscript brain age gap analyses. In the manuscript, a deep learning brain-age prediction model estimates functional brain age from early-life FC heatmaps/features, and BAG is evaluated as predicted age minus chronological age for neurodevelopmental risk-group deviation and classification analyses.

## Demo code

Files:

- `demo/generate_simulated_demo_data.py`
- `demo/run_demo.m`

Purpose:

- Provide a small, non-identifiable simulated dataset for a CCA-only runnable demo.
- Demonstrate compact brain-feature, behavior, and covariate table formats.
- Provide reviewers with a fast check of MATLAB execution and CCA output structure without approximating the spline-based mSFPCA pipeline.

Demo pseudocode:

```text
read simulated subject, brain-feature, behavior, and covariate tables
verify that subject order is consistent across tables
residualize brain and behavior variables for simulated covariates
z-score residualized brain and behavior matrices
run CCA using MATLAB canoncorr when available or a QR/SVD fallback
compute loadings as correlations between original variables and canonical scores
write canonical correlations, subject canonical scores, brain loadings, and behavior loadings
plot the first brain and behavior canonical scores
plot first-dimension brain and behavior loadings
```

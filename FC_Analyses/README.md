# FC Trajectories code and demo package

This package accompanies the manuscript **"Functional brain growth trajectories across the first decade of life from a single longitudinal cohort"** submitted to *Nature Human Behaviour*.

The directory contains reorganized analysis scripts copied from the original `codes/` directory, a small simulated dataset, and a MATLAB CCA demo showing the expected brain-behavior matrix format and execution flow. The simulated demo data are not real cohort data and are not intended to reproduce the manuscript's quantitative results.

Open-source repository: https://github.com/harry3111/FC_Trajectories

## Directory structure

```text
codes_reorg/
  README.md
  LICENSE
  requirements_python.txt
  code/
    00_preprocessing/
    01_gradient_heatmap_generation/
    02_heatmap_features_harmonization/
    03_mfpca_trajectories/
    04_cca_behavior/
    05_bag_analysis/
    support_files/
  demo/
    generate_simulated_demo_data.py
    run_demo.m
    data/
    outputs/
  docs/
    code_functionality.md
    manuscript_mapping.md
```

The original analysis scripts are preserved as source code and grouped by analysis stage. Their scientific content and analysis logic were not changed during reorganization.

## System requirements

### Operating systems

- Package assembly, file-structure validation, and MATLAB demo execution were tested on Windows 11 10.0.26200.
- The original manuscript analyses were run from absolute Linux paths in the submitted scripts and require local path updates before rerunning on another system.
- The demo uses relative paths and should run on Windows, macOS, or Linux with MATLAB installed.

### Versions tested

- Python data-generation script: tested with Python 3.11.15.
- Package inventory and README validation: tested on Windows 11 10.0.26200.
- MATLAB demo runner: tested with MATLAB R2023b Update 5 on Windows 11 10.0.26200.

### MATLAB requirements

Recommended:

- MATLAB R2021a or later.
- Statistics and Machine Learning Toolbox for `canoncorr` in the demo.
- Image Processing Toolbox and/or NIfTI toolbox may be required for manuscript scripts that read or write NIfTI files.
- CCA/PLS Toolkit is required for full CCA scripts in `code/04_cca_behavior/`.
- mFPCA or functional data analysis utilities used in the manuscript analysis must be available on the MATLAB path when rerunning the full spline-based trajectory analyses.

The demo includes a QR/SVD fallback for the CCA calculation if `canoncorr` is unavailable, but the full manuscript CCA scripts still require the CCA/PLS Toolkit.

### Python requirements

Recommended:

- Python 3.9 or later.
- The simulated demo data generator uses only the Python standard library.
- Required packages for the Python manuscript scripts are listed in `requirements_python.txt`:
  - `numpy`
  - `pandas`
  - `matplotlib`
  - `nibabel`
  - `neuroCombat`
  - `brainspace`

### Non-standard hardware

No non-standard hardware is required for the simulated demo. Rerunning the full manuscript pipeline on the complete cohort and voxelwise/ROI-level data benefits from a workstation or compute server with sufficient memory and storage, but no GPU is required by the provided scripts.

## Installation guide

1. Download or clone the repository.
2. Open MATLAB and set the current folder to `codes_reorg/`.
3. Optional: install Python dependencies for Python-based manuscript scripts:

   ```bash
   python -m pip install -r requirements_python.txt
   ```

4. For full manuscript analyses, add required external MATLAB toolboxes to the MATLAB path, including the CCA/PLS Toolkit, mFPCA utilities, and NIfTI utilities used by the original scripts.
5. Update the hard-coded local paths in the manuscript scripts to point to your approved local copy of the cohort data and derivative files.

Typical install time on a normal desktop computer is approximately 5-10 minutes for the demo package, excluding MATLAB installation and any controlled-access cohort data transfer.

## Demo

The demo uses only simulated data in `demo/data/`.

The runnable demo is intentionally limited to a small CCA example because the full gradient, heatmap-feature generation/harmonization, and spline-based mSFPCA/mFPCA analyses depend on the original neuroimaging derivatives, local paths, and external toolboxes. Those analyses should be reviewed in the original scripts under `code/01_gradient_heatmap_generation/`, `code/02_heatmap_features_harmonization/`, and `code/03_mfpca_trajectories/` rather than inferred from a simplified toy implementation.

The CCA demo reads simulated brain-feature, behavior, and covariate tables; residualizes brain and behavior variables for the simulated covariates; runs CCA; and writes canonical correlations, subject scores, loadings, and a diagnostic score plot.

### Demo input files

- `demo/data/simulated_subjects.csv`: subject IDs and simple grouping variables.
- `demo/data/simulated_brain_features.csv`: simulated brain-derived variables resembling network, gradient, or trajectory summary features.
- `demo/data/simulated_behavior.csv`: simulated behavioral variables.
- `demo/data/simulated_covariates.csv`: simulated covariates used for residualization before CCA.

### Run the demo

From MATLAB:

```matlab
cd codes_reorg
run('demo/run_demo.m')
```

### Expected output

After successful completion, MATLAB prints a completion message and creates:

- `demo/outputs/demo_cca_results.csv`
- `demo/outputs/demo_cca_subject_scores.csv`
- `demo/outputs/demo_cca_loadings_brain.csv`
- `demo/outputs/demo_cca_loadings_behavior.csv`
- `demo/outputs/demo_cca_scores.png`
- `demo/outputs/demo_cca_loadings.png`

Expected demo runtime on a normal desktop computer is less than 1 minute.

To regenerate the simulated input files:

```bash
python demo/generate_simulated_demo_data.py
```

## Instructions for use on study data

The full manuscript scripts require controlled-access longitudinal neuroimaging, behavioral, and covariate files. To run the manuscript workflow on approved data:

1. Obtain access to the required cohort data under the appropriate data use agreement.
2. Prepare input files matching the naming conventions used by the scripts, including subject lists, FC matrices, heatmaps, covariate tables, age-specific outputs, and behavioral measures.
3. Update the path variables near the top of each script to point to your local data and output directories.
4. Run the scripts stage by stage in the order described below:
   - `code/00_preprocessing/`: preprocessing support and T1 alignment utilities.
   - `code/01_gradient_heatmap_generation/`: functional gradient estimation, gradient-derived heatmap generation, alignment, and visualization.
   - `code/02_heatmap_features_harmonization/`: heatmap-derived feature generation, ROI/network summaries, ComBat harmonization where applicable, group comparisons, regressions, and partial correlations.
   - `code/03_mfpca_trajectories/`: construction of trajectory tables, spline-based mSFPCA/mFPCA reconstruction, and trajectory statistics.
   - `code/04_cca_behavior/`: CCA/PLS behavioral association analyses.
   - `code/05_bag_analysis/`: brain age gap (BAG) analyses, where a deep learning brain-age prediction model estimates functional brain age from early-life FC heatmaps/features and BAG is evaluated as predicted age minus chronological age for neurodevelopmental risk-group analyses.

The demo data can be used as a template for compact CCA inputs, but the full manuscript scripts use additional NIfTI, `.mat`, `.1D`, Excel, and text-list inputs.

## Code functionality

A detailed stage-by-stage description and pseudocode are provided in `docs/code_functionality.md`.

Briefly, the code:

1. Organizes cohort-level neuroimaging and covariate files.
2. Computes functional connectivity gradients and gradient-derived heatmap summaries.
3. Harmonizes scanner/site-related effects with ComBat while preserving biological covariates.
4. Builds longitudinal feature tables and estimates functional growth trajectories using spline-based mSFPCA/mFPCA analyses.
5. Tests group differences, developmental associations, and behavior-brain associations, including CCA/PLS analyses.
6. Includes `code/05_bag_analysis/` for the manuscript brain age gap analyses.

## Manuscript mapping

The relationship between code folders and manuscript sections is summarized in `docs/manuscript_mapping.md`. The code functionality is described primarily in the manuscript Methods section and related Supplementary Methods/Results sections.

## Reproduction notes

The included simulated demo demonstrates software installation, CCA input format, and basic execution. It does not reproduce manuscript figures, tables, or statistics.

Full quantitative reproduction requires:

- approved access to the original longitudinal cohort data;
- the same preprocessing derivatives used in the manuscript;
- external MATLAB/Python toolboxes listed above;
- local path configuration for the manuscript scripts;
- sufficient storage for neuroimaging derivatives and intermediate outputs.

## Data availability

The real participant data are not included in this package because access requires a data use agreement. The files in `demo/data/` are fully simulated and contain no real participant information.

## Software license

Original code and documentation prepared for this package are released under the MIT License in `LICENSE`. Third-party software, toolboxes, and any code segments retaining their original headers remain subject to their respective licenses, including the CCA/PLS Toolkit components referenced by the CCA scripts.

## Citation

If using this code, please cite the accompanying manuscript:

Gao and colleagues, "Functional brain growth trajectories across the first decade of life from a single longitudinal cohort", submitted to *Nature Human Behaviour*.

## Contact

For questions about the manuscript code package, please contact the corresponding author listed in the manuscript submission.

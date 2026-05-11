# BrainDev

Workflow for BAG estimation and downstream classification:

- **Brain age estimation** from multi-channel functional heatmaps using a semi-supervised PyTorch model.
- **Clinical-group classification** from functional-connectivity features and optional brain-age gap features.

The repository includes runnable synthetic demos for both parts so users can validate the code path before preparing real data.

> The demo datasets are synthetic and are intended only for software validation. They do not evaluate model accuracy or clinical utility.

## Contents

- [Repository Structure](#repository-structure)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Brain Age Estimation](#brain-age-estimation)
- [Classification](#classification)
- [Data Formats](#data-formats)
- [Outputs](#outputs)
- [Provenance](#provenance)

## Repository Structure

```text
brain_dev_release/
  brain_age/
    infer_ssl.py                  # subject-level brain-age inference
    train_ssl.py                  # SSL training script
    dataloader2d.py
    checkpoints/best_epoch.pth    # packaged checkpoint for inference/demo
    models/
    util/
  classification/
    linear_cv.py                  # portable subject-level classifier
    build_clean_classification_data.py
    *_reference.py                # retained analysis scripts
  demos/
    make_brain_age_demo.py
    make_classification_demo.py
    run_brain_age_demo.sh
    run_classification_demo.sh
  demo_data/                      # generated synthetic demo inputs
  demo_outputs/                   # generated demo outputs
  requirements.txt
```

## Installation

Create an environment and install dependencies:

```bash
# From a cloned copy of this repository:
cd BrainDev

python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

## Quick Start

Run both demos from the repository root:

```bash
bash demos/run_brain_age_demo.sh
bash demos/run_classification_demo.sh
```

Expected demo outputs:

```text
demo_outputs/brain_age/brain_age_predictions.csv
demo_outputs/classification/ndd_pca5_with_agegap/model_summary.csv
```

## Brain Age Estimation

The brain-age module loads multi-modality `.npy` heatmap slices, runs the SSL checkpoint, averages slice-level age distributions, and writes one prediction per subject visit.

### Demo

```bash
python demos/make_brain_age_demo.py
python brain_age/infer_ssl.py \
  --guide-path demo_data/brain_age/subjects.csv \
  --weighted-path demo_data/brain_age/heatmaps \
  --checkpoint brain_age/checkpoints/best_epoch.pth \
  --output-dir demo_outputs/brain_age \
  --splits valid \
  --batch-size 8 \
  --num-workers 0 \
  --max-slices 8 \
  --device cpu
```

### Real Inference

```bash
python brain_age/infer_ssl.py \
  --guide-path /path/to/guide.csv \
  --weighted-path /path/to/heatmaps \
  --checkpoint brain_age/checkpoints/best_epoch.pth \
  --output-dir /path/to/brain_age_output \
  --splits valid,AD,AU,MPD
```

Default heatmap modalities:

```text
Elocal, Enodal, Gradient1, Gradient2, McosSim2, Str
```

Use `--modalities` to override this list. The packaged checkpoint expects six input channels.

### Training

Training is available through `brain_age/train_ssl.py`. Run it from the `brain_age` directory because the original training code uses local imports:

```bash
cd brain_age
python train_ssl.py \
  --guide_path /path/to/guide.csv \
  --weighted_path /path/to/heatmaps \
  --map_path /path/to/maps_or_placeholder \
  --output_dir /path/to/train_output \
  --elocal_image --enodal_image --gradient1_image --gradient2_image --McosSim2_image --str_image \
  --ext_label_cols "SB_ABIQ_ss_6,PR_BASC_ANX_T_6,PR_BASC_DEP_T_6"
```

## Classification

The classification module performs subject-level cross-validation on tabular functional-connectivity features, with optional brain-age gap features. It supports raw FC features, PCA-reduced FC features, AgeGap ablation, and random-feature controls.

### Demo

```bash
python demos/make_classification_demo.py
python classification/linear_cv.py \
  --data-dir demo_data/classification \
  --branch ndd \
  --feature-mode pca5_with_agegap \
  --n-folds 3 \
  --seed 42 \
  --models logistic_l2 ridge \
  --output-dir demo_outputs/classification/ndd_pca5_with_agegap
```

### Real Classification

```bash
python classification/linear_cv.py \
  --dataset-csv /path/to/dataset.csv \
  --feature-mode pca5_with_agegap \
  --n-folds 10 \
  --seed 42 \
  --models logistic_l2 logistic_l1 ridge sgd_log sgd_hinge \
  --output-dir /path/to/classification_output
```

Supported feature modes:

| Mode | Features |
| --- | --- |
| `with_agegap` | Raw FC features plus `AgeGap` |
| `without_agegap` | Raw FC features only |
| `random_feature` | Raw FC features plus random control feature |
| `pca5_with_agegap` | Five FC principal components plus `AgeGap` |
| `pca5_without_agegap` | Five FC principal components only |
| `pca5_random_feature` | Five FC principal components plus random control feature |

Available linear models:

```text
logistic_l2, logistic_l1, logistic_en, ridge, ridge_a10, linear_svc, sgd_log, sgd_hinge
```

## Data Formats

### Brain Age Guide CSV

Required columns:

| Column | Description |
| --- | --- |
| `Subjects` | Subject identifier |
| `AgeYear` | Visit age bin/year label |
| `GASDay` | Chronological age in days |
| `mode` | Split name, such as `train`, `valid`, `AD`, `AU`, or `MPD` |

Heatmap directory layout:

```text
<heatmap_root>/<modality>/<Subjects>/<GASDay>/<slice>.npy
```

Example:

```text
demo_data/brain_age/heatmaps/Elocal/simBA001/300/00.npy
```

### Classification CSV

Required columns:

| Column | Description |
| --- | --- |
| `Subjects` | Subject identifier; folds are assigned at this level |
| `Class` | Binary class label, `0` or `1` |
| `AgeGap` | Brain-age gap feature, typically predicted age minus chronological age |

Optional metadata columns:

```text
ScanKey, AgeYear, GASDay, Age, PredictAge, Cohort
```

Functional-connectivity columns must use these prefixes:

```text
Elocal_, Enodal_, Gradient1_, Gradient2_, McosSim2_, Str_
```

## Outputs

### Brain Age

`brain_age/infer_ssl.py` writes:

| File | Description |
| --- | --- |
| `brain_age_predictions.csv` | One row per subject visit with predicted age and age gap |
| `summary.json` | Run metadata and mean absolute age gap |
| `plots/*.png` | Optional predicted age-distribution plots |

Prediction CSV columns:

```text
split, subject, ageyear, gasday, chronological_age_days,
predicted_age_days, age_gap_days, n_slices
```

### Classification

`classification/linear_cv.py` writes:

| File | Description |
| --- | --- |
| `fold_model_metrics.csv` | Metrics for each fold and model |
| `model_summary.csv` | Mean/std metrics by model |
| `all_test_predictions.csv` | Held-out predictions across folds |
| `run_metadata.json` | Dataset path, feature mode, folds, seed, and models |

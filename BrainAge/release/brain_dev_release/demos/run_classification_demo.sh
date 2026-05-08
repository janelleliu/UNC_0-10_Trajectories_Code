#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_PY="/common/lidxxlab/Yifan/envs/BrainAge/bin/python"
if [[ -x "${DEFAULT_PY}" ]]; then
  PYTHON_BIN="${PYTHON_BIN:-${DEFAULT_PY}}"
else
  PYTHON_BIN="${PYTHON_BIN:-python}"
fi

cd "${ROOT_DIR}"

"${PYTHON_BIN}" demos/make_classification_demo.py
"${PYTHON_BIN}" classification/linear_cv.py \
  --data-dir demo_data/classification \
  --branch ndd \
  --feature-mode pca5_with_agegap \
  --n-folds 3 \
  --seed 42 \
  --models logistic_l2 ridge \
  --output-dir demo_outputs/classification/ndd_pca5_with_agegap

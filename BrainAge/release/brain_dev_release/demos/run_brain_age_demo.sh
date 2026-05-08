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

"${PYTHON_BIN}" demos/make_brain_age_demo.py
"${PYTHON_BIN}" brain_age/infer_ssl.py \
  --guide-path demo_data/brain_age/subjects.csv \
  --weighted-path demo_data/brain_age/heatmaps \
  --checkpoint brain_age/checkpoints/best_epoch.pth \
  --output-dir demo_outputs/brain_age \
  --splits valid \
  --batch-size 8 \
  --num-workers 0 \
  --max-slices 8 \
  --device cpu

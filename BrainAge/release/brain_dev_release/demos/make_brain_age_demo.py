#!/usr/bin/env python3
"""Generate a three-subject synthetic heatmap demo for brain-age inference."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd


MODALITIES = ["Elocal", "Enodal", "Gradient1", "Gradient2", "McosSim2", "Str"]


def parse_args() -> argparse.Namespace:
    release_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-root", default=str(release_root / "demo_data" / "brain_age"))
    parser.add_argument("--n-slices", type=int, default=12)
    parser.add_argument("--seed", type=int, default=2026)
    return parser.parse_args()


def make_blob(height: int, width: int, centre_x: float, centre_y: float, sigma: float) -> np.ndarray:
    yy, xx = np.mgrid[0:height, 0:width]
    return np.exp(-(((xx - centre_x) ** 2 + (yy - centre_y) ** 2) / (2.0 * sigma**2)))


def main() -> None:
    args = parse_args()
    output_root = Path(args.output_root)
    heatmap_root = output_root / "heatmaps"
    output_root.mkdir(parents=True, exist_ok=True)

    rng = np.random.default_rng(args.seed)
    subjects = [
        ("simBA001", 0, 300),
        ("simBA002", 1, 665),
        ("simBA003", 2, 1030),
    ]

    rows = []
    height, width = 96, 80
    for subject_index, (subject, ageyear, gasday) in enumerate(subjects):
        age_scale = gasday / 1200.0
        rows.append({"Subjects": subject, "AgeYear": ageyear, "GASDay": gasday, "mode": "valid"})

        for modality_index, modality in enumerate(MODALITIES):
            out_dir = heatmap_root / modality / subject / str(gasday)
            out_dir.mkdir(parents=True, exist_ok=True)
            modality_shift = (modality_index - 2.5) * 0.03

            for slice_id in range(args.n_slices):
                centre_x = width * (0.45 + 0.04 * np.sin(slice_id / 3.0 + subject_index))
                centre_y = height * (0.50 + 0.04 * np.cos(slice_id / 4.0 + modality_index))
                sigma = 12.0 + 0.6 * modality_index + 0.04 * gasday / 30.0
                blob = make_blob(height, width, centre_x, centre_y, sigma)
                gradient = np.linspace(0, 1, width, dtype=np.float32)[None, :]
                noise = rng.normal(0.0, 0.025, size=(height, width))
                image = 0.25 + 0.55 * blob + 0.10 * gradient + 0.08 * age_scale + modality_shift + noise
                image = np.clip(image, 0.0, None).astype(np.float32)
                np.save(out_dir / f"{slice_id:02d}.npy", image)

    guide = pd.DataFrame(rows)
    guide_path = output_root / "subjects.csv"
    guide.to_csv(guide_path, index=False)
    print(f"Wrote brain-age demo guide: {guide_path}")
    print(f"Wrote synthetic heatmaps: {heatmap_root}")


if __name__ == "__main__":
    main()

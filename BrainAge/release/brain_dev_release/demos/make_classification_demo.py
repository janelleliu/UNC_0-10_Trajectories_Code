#!/usr/bin/env python3
"""Generate simulated BrainDev classification datasets.

The demo data mimic the release classification table shape: subject IDs,
age visits, six functional-connectivity feature families, AgeGap, and a
binary Class label. These are synthetic data for code demonstration only.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd


MODALITIES = ["Elocal", "Enodal", "Gradient1", "Gradient2", "McosSim2", "Str"]
NETWORKS = ["VIS", "SMN", "DAN", "SAL", "LIM", "FPN", "DMN", "SUB"]


def parse_args() -> argparse.Namespace:
    release_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-root", default=str(release_root / "demo_data" / "classification"))
    parser.add_argument("--n-subjects", type=int, default=60)
    parser.add_argument("--seed", type=int, default=2026)
    return parser.parse_args()


def make_branch(branch: str, n_subjects: int, rng: np.random.Generator) -> pd.DataFrame:
    rows = []
    positive_rate = 0.45 if branch == "ndd" else 0.62
    branch_shift = 0.35 if branch == "ndd_mpd" else 0.0

    subject_classes = rng.binomial(1, positive_rate, size=n_subjects)
    # Keep both classes present even for tiny requested demos.
    subject_classes[:2] = [0, 1]

    for subject_index, cls in enumerate(subject_classes):
        subject = f"simCLS{subject_index + 1:03d}"
        subject_trait = rng.normal(0.0, 0.35)
        for ageyear in [0, 1, 2]:
            gasday = int(300 + 365 * ageyear + rng.normal(0, 18))
            chronological_age = float(gasday)
            agegap = rng.normal(0, 45) + cls * (75 + 10 * ageyear) + subject_trait * 20 + branch_shift * 20
            predicted_age = chronological_age + agegap

            row = {
                "ScanKey": f"{subject}_AY{ageyear}_GD{gasday}",
                "Subjects": subject,
                "AgeYear": ageyear,
                "GASDay": gasday,
                "Age": chronological_age,
                "PredictAge": predicted_age,
                "AgeGap": agegap,
                "Class": int(cls),
                "Cohort": "positive" if cls else "healthy",
            }

            for modality_index, modality in enumerate(MODALITIES):
                for network_index, network in enumerate(NETWORKS):
                    signal = (
                        0.18 * cls * np.sin((network_index + 1) / 2.0)
                        + 0.03 * ageyear
                        + 0.02 * modality_index
                        + subject_trait * 0.05
                    )
                    row[f"{modality}_{network}"] = rng.normal(0.0, 1.0) + signal
            rows.append(row)

    return pd.DataFrame(rows)


def main() -> None:
    args = parse_args()
    output_root = Path(args.output_root)
    output_root.mkdir(parents=True, exist_ok=True)

    rng = np.random.default_rng(args.seed)
    for branch in ["ndd", "ndd_mpd"]:
        branch_df = make_branch(branch, args.n_subjects, rng)
        branch_dir = output_root / branch
        branch_dir.mkdir(parents=True, exist_ok=True)
        branch_df.to_csv(branch_dir / "dataset.csv", index=False)
        subject_summary = branch_df[["Subjects", "Class"]].drop_duplicates()["Class"].value_counts().sort_index()
        print(f"{branch}: wrote {branch_dir / 'dataset.csv'}")
        print(f"{branch}: subjects per class {subject_summary.to_dict()}")


if __name__ == "__main__":
    main()

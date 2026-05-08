#!/usr/bin/env python3
"""Subject-level inference for the BrainDev SSL brain-age model.

This wrapper keeps the original checkpoint/model architecture but makes
inference deterministic and release-friendly:

* input paths are provided on the command line;
* slices are iterated once, not randomly sampled;
* slice distributions are averaged into one prediction per subject visit;
* outputs are written as CSV plus optional distribution plots.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path

import numpy as np
import pandas as pd
import torch
import torch.nn.functional as F
from torch.utils.data import DataLoader, Dataset


SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from models.Extend3DModel import FunctionAgePredictionModel_SSL  # noqa: E402


DEFAULT_MODALITIES = ["Elocal", "Enodal", "Gradient1", "Gradient2", "McosSim2", "Str"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--guide-path", required=True, help="CSV with Subjects, AgeYear, GASDay, and mode columns.")
    parser.add_argument("--weighted-path", required=True, help="Root containing modality/subject/GASDay/*.npy heatmaps.")
    parser.add_argument("--checkpoint", required=True, help="Path to a FunctionAgePredictionModel_SSL state_dict.")
    parser.add_argument("--output-dir", required=True, help="Directory for predictions and plots.")
    parser.add_argument("--splits", default="valid", help="Comma-separated mode values to infer, e.g. valid,AD,AU,MPD.")
    parser.add_argument("--modalities", default=",".join(DEFAULT_MODALITIES), help="Comma-separated heatmap modalities.")
    parser.add_argument("--batch-size", type=int, default=8)
    parser.add_argument("--num-workers", type=int, default=0)
    parser.add_argument("--max-subjects", type=int, default=None, help="Optional cap per split for demos/smoke tests.")
    parser.add_argument("--max-slices", type=int, default=20, help="Use the central N slices per subject visit.")
    parser.add_argument("--age-bin-width", type=float, default=4.0, help="Age-distribution bin width in days.")
    parser.add_argument("--device", default="auto", choices=["auto", "cpu", "cuda"])
    parser.add_argument("--no-plots", action="store_true", help="Skip per-subject distribution PNGs.")
    return parser.parse_args()


def split_csv(value: str) -> list[str]:
    return [item.strip() for item in value.split(",") if item.strip()]


def numeric_sort_key(path: Path) -> tuple[int, str]:
    try:
        return int(path.stem), path.name
    except ValueError:
        return 10**9, path.name


class HeatmapSliceDataset(Dataset):
    """Deterministic slice dataset for SSL brain-age inference."""

    def __init__(
        self,
        guide_path: Path,
        weighted_path: Path,
        split: str,
        modalities: list[str],
        max_subjects: int | None = None,
        max_slices: int | None = 20,
    ) -> None:
        self.split = split
        self.weighted_path = weighted_path
        self.modalities = modalities
        self.samples: list[dict] = []

        df = pd.read_csv(guide_path)
        required = {"Subjects", "AgeYear", "GASDay", "mode"}
        missing = sorted(required - set(df.columns))
        if missing:
            raise ValueError(f"Guide CSV is missing required columns: {missing}")

        df = df[df["mode"].astype(str) == split].copy()
        if df.empty:
            raise ValueError(f"No rows found for split '{split}' in {guide_path}")

        subject_visits = 0
        grouped = df.groupby(["Subjects", "AgeYear", "GASDay"], sort=True)
        for (subject, ageyear, gasday), _ in grouped:
            if max_subjects is not None and subject_visits >= max_subjects:
                break

            dirs = [weighted_path / modality / str(subject) / str(int(gasday)) for modality in modalities]
            if any(not d.is_dir() for d in dirs):
                continue

            first_slices = sorted(dirs[0].glob("*.npy"), key=numeric_sort_key)
            slice_names = [path.name for path in first_slices if all((d / path.name).is_file() for d in dirs)]
            if not slice_names:
                continue

            if max_slices is not None and len(slice_names) > max_slices:
                start = (len(slice_names) - max_slices) // 2
                slice_names = slice_names[start : start + max_slices]

            for slice_name in slice_names:
                self.samples.append(
                    {
                        "subject": str(subject),
                        "ageyear": int(ageyear),
                        "gasday": float(gasday),
                        "paths": [d / slice_name for d in dirs],
                    }
                )
            subject_visits += 1

        if not self.samples:
            raise RuntimeError(
                f"No loadable heatmap slices for split '{split}'. Check --weighted-path, modalities, and GASDay folders."
            )

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, index: int):
        item = self.samples[index]
        channels = []
        for path in item["paths"]:
            arr = np.squeeze(np.load(path)).astype(np.float32)
            arr = arr / (float(np.nanmax(arr)) + 1e-8)
            channels.append(np.nan_to_num(arr, nan=0.0, posinf=0.0, neginf=0.0))

        image = np.stack(channels, axis=2)
        image = np.rot90(image, axes=(0, 1)).copy()
        tensor = torch.from_numpy(image.transpose(2, 0, 1)).float()
        tensor = (tensor - 0.5) / (0.5 + 1e-8)
        return tensor, item["subject"], item["ageyear"], item["gasday"]


def infer_model_shape(checkpoint: dict) -> tuple[int, int]:
    input_channels = int(checkpoint["backbone.conv1.0.weight"].shape[1])
    n_ext_labels = int(checkpoint["ext_head.weight"].shape[0])
    return input_channels, n_ext_labels


def load_model(checkpoint_path: Path, device: torch.device) -> FunctionAgePredictionModel_SSL:
    checkpoint = torch.load(checkpoint_path, map_location=device)
    input_channels, n_ext_labels = infer_model_shape(checkpoint)
    model = FunctionAgePredictionModel_SSL(
        input_channel=input_channels,
        n_ext_labels=n_ext_labels,
        drop_out_rate=0.0,
        add_xgb=None,
    ).to(device)
    model.load_state_dict(checkpoint)
    model.eval()
    return model


def save_distribution_plot(age_centres: np.ndarray, probability: np.ndarray, row: dict, output_dir: Path) -> None:
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    plot_dir = output_dir / "plots"
    plot_dir.mkdir(parents=True, exist_ok=True)
    plt.figure(figsize=(7, 4))
    plt.plot(age_centres, probability)
    plt.axvline(row["predicted_age_days"], color="tab:red", linestyle="--", linewidth=1)
    plt.xlabel("Age (days)")
    plt.ylabel("Probability")
    plt.title(f"{row['split']} {row['subject']} age={row['chronological_age_days']:.0f}d")
    plt.tight_layout()
    filename = f"{row['split']}_{row['subject']}_AY{row['ageyear']}_GD{int(row['gasday'])}.png"
    plt.savefig(plot_dir / filename, dpi=160)
    plt.close()


def run_split(
    args: argparse.Namespace,
    model: FunctionAgePredictionModel_SSL,
    split: str,
    modalities: list[str],
    device: torch.device,
    output_dir: Path,
) -> list[dict]:
    dataset = HeatmapSliceDataset(
        guide_path=Path(args.guide_path),
        weighted_path=Path(args.weighted_path),
        split=split,
        modalities=modalities,
        max_subjects=args.max_subjects,
        max_slices=args.max_slices,
    )
    loader = DataLoader(
        dataset,
        batch_size=args.batch_size,
        shuffle=False,
        num_workers=args.num_workers,
        pin_memory=device.type == "cuda",
    )

    age_centres_t = torch.arange(1024, dtype=torch.float32, device=device) * float(args.age_bin_width)
    age_centres = age_centres_t.detach().cpu().numpy()
    by_visit: dict[tuple[str, int, float], list[np.ndarray]] = defaultdict(list)

    with torch.no_grad():
        for images, subjects, ageyears, gasdays in loader:
            images = images.to(device)
            logits, _, _ = model(images)
            probs = F.softmax(logits, dim=1).detach().cpu().numpy()
            for i, subject in enumerate(subjects):
                key = (str(subject), int(ageyears[i]), float(gasdays[i]))
                by_visit[key].append(probs[i])

    rows = []
    for (subject, ageyear, gasday), prob_list in sorted(by_visit.items()):
        mean_prob = np.mean(np.vstack(prob_list), axis=0)
        pred_age = float(np.sum(mean_prob * age_centres))
        row = {
            "split": split,
            "subject": subject,
            "ageyear": int(ageyear),
            "gasday": float(gasday),
            "chronological_age_days": float(gasday),
            "predicted_age_days": pred_age,
            "age_gap_days": pred_age - float(gasday),
            "n_slices": len(prob_list),
        }
        rows.append(row)
        if not args.no_plots:
            save_distribution_plot(age_centres, mean_prob, row, output_dir)

    return rows


def main() -> None:
    args = parse_args()
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    if args.device == "auto":
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    else:
        device = torch.device(args.device)

    modalities = split_csv(args.modalities)
    model = load_model(Path(args.checkpoint), device)
    expected_channels, _ = infer_model_shape(torch.load(args.checkpoint, map_location="cpu"))
    if len(modalities) != expected_channels:
        raise ValueError(
            f"Checkpoint expects {expected_channels} input channels, but --modalities has {len(modalities)} entries."
        )

    all_rows = []
    for split in split_csv(args.splits):
        all_rows.extend(run_split(args, model, split, modalities, device, output_dir))

    predictions = pd.DataFrame(all_rows)
    predictions.to_csv(output_dir / "brain_age_predictions.csv", index=False)
    summary = {
        "n_predictions": int(len(predictions)),
        "splits": sorted(predictions["split"].unique().tolist()) if not predictions.empty else [],
        "mean_abs_age_gap_days": float(predictions["age_gap_days"].abs().mean()) if not predictions.empty else None,
        "device": str(device),
        "modalities": modalities,
    }
    (output_dir / "summary.json").write_text(json.dumps(summary, indent=2))
    print(predictions.to_string(index=False))
    print(f"\nWrote predictions to {output_dir / 'brain_age_predictions.csv'}")


if __name__ == "__main__":
    main()

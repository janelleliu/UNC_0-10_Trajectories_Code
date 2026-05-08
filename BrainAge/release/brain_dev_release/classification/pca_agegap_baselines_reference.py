#!/usr/bin/env python3

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.decomposition import PCA
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, f1_score, roc_auc_score
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler


ROOT = Path("/common/lidxxlab/Yifan/BrainDev")
CLASS_DIR = ROOT / "code" / "Classification"
DATA_DIR = CLASS_DIR / "lists" / "clean_cv"
OUT_DIR = CLASS_DIR / "pca_agegap_results"
FC_PREFIXES = ["Elocal_", "Enodal_", "Gradient1_", "Gradient2_", "McosSim2_", "Str_"]
BRANCHES = ["ndd", "ndd_mpd"]
CONFIGS = [
    ("agegap_only", None, True),
    ("pca5", 5, False),
    ("pca5_agegap", 5, True),
    ("pca10", 10, False),
    ("pca10_agegap", 10, True),
]


def load_dataset(branch: str) -> pd.DataFrame:
    df = pd.read_csv(DATA_DIR / branch / "dataset.csv")
    df["Fold"] = pd.to_numeric(df["Fold"], errors="coerce").astype(int)
    df["Class"] = pd.to_numeric(df["Class"], errors="coerce").astype(int)
    df["AgeGap"] = pd.to_numeric(df["AgeGap"], errors="coerce")
    return df


def get_fc_columns(df: pd.DataFrame) -> list[str]:
    return [col for col in df.columns if any(col.startswith(prefix) for prefix in FC_PREFIXES)]


def build_pipeline(n_components: int | None) -> Pipeline:
    steps = [
        ("imputer", SimpleImputer(strategy="median")),
        ("scaler", StandardScaler()),
    ]
    if n_components is not None:
        steps.append(("pca", PCA(n_components=n_components, svd_solver="full")))
    steps.append(
        (
            "clf",
            LogisticRegression(
                solver="liblinear",
                class_weight="balanced",
                max_iter=5000,
                random_state=0,
            ),
        )
    )
    return Pipeline(steps)


def evaluate_fold(
    train_df: pd.DataFrame,
    test_df: pd.DataFrame,
    fc_cols: list[str],
    n_components: int | None,
    use_agegap: bool,
) -> tuple[dict, pd.DataFrame]:
    if n_components is None and not use_agegap:
        raise ValueError("At least one feature source is required.")

    if n_components is None:
        train_X = train_df[["AgeGap"]].copy()
        test_X = test_df[["AgeGap"]].copy()
        model = build_pipeline(None)
        model.fit(train_X, train_df["Class"])
        n_pca_used = 0
        explained = np.nan
    else:
        fc_model = build_pipeline(n_components)
        train_fc = train_df[fc_cols].copy()
        test_fc = test_df[fc_cols].copy()

        if use_agegap:
            fc_only = Pipeline(fc_model.steps[:-1])
            fc_only.fit(train_fc)
            train_fc_emb = fc_only.transform(train_fc)
            test_fc_emb = fc_only.transform(test_fc)

            agegap_imputer = SimpleImputer(strategy="median")
            agegap_scaler = StandardScaler()
            train_agegap = agegap_scaler.fit_transform(agegap_imputer.fit_transform(train_df[["AgeGap"]]))
            test_agegap = agegap_scaler.transform(agegap_imputer.transform(test_df[["AgeGap"]]))

            train_X = np.hstack([train_fc_emb, train_agegap])
            test_X = np.hstack([test_fc_emb, test_agegap])
            model = LogisticRegression(
                solver="liblinear",
                class_weight="balanced",
                max_iter=5000,
                random_state=0,
            )
            model.fit(train_X, train_df["Class"])
            pca_step = fc_only.named_steps["pca"]
            n_pca_used = int(pca_step.n_components_)
            explained = float(np.sum(pca_step.explained_variance_ratio_))
        else:
            model = fc_model
            model.fit(train_fc, train_df["Class"])
            train_X = train_fc
            test_X = test_fc
            pca_step = model.named_steps["pca"]
            n_pca_used = int(pca_step.n_components_)
            explained = float(np.sum(pca_step.explained_variance_ratio_))

    y_test = test_df["Class"].to_numpy()
    y_pred = model.predict(test_X)
    y_score = model.predict_proba(test_X)[:, 1]

    metrics = {
        "accuracy": float(accuracy_score(y_test, y_pred)),
        "f1_macro": float(f1_score(y_test, y_pred, average="macro")),
        "auroc": float(roc_auc_score(y_test, y_score)),
        "n_pca_components": int(n_pca_used),
        "pca_explained_variance": explained,
        "train_rows": int(len(train_df)),
        "test_rows": int(len(test_df)),
        "train_subjects": int(train_df["Subjects"].nunique()),
        "test_subjects": int(test_df["Subjects"].nunique()),
        "confusion_matrix": confusion_matrix(y_test, y_pred).tolist(),
        "classification_report": classification_report(y_test, y_pred, digits=4),
    }

    pred_df = test_df[["ScanKey", "Subjects", "AgeYear", "GASDay", "Class", "Fold"]].copy()
    pred_df["PredLabel"] = y_pred
    pred_df["PredScore"] = y_score
    return metrics, pred_df


def run_branch_config(branch: str, config_name: str, n_components: int | None, use_agegap: bool) -> dict:
    df = load_dataset(branch)
    fc_cols = get_fc_columns(df)
    branch_dir = OUT_DIR / branch / config_name
    branch_dir.mkdir(parents=True, exist_ok=True)

    fold_rows = []
    pred_frames = []
    for fold in sorted(df["Fold"].unique()):
        train_df = df[df["Fold"] != fold].copy()
        test_df = df[df["Fold"] == fold].copy()
        metrics, pred_df = evaluate_fold(
            train_df=train_df,
            test_df=test_df,
            fc_cols=fc_cols,
            n_components=n_components,
            use_agegap=use_agegap,
        )

        fold_record = {
            "fold": int(fold),
            "accuracy": metrics["accuracy"],
            "f1_macro": metrics["f1_macro"],
            "auroc": metrics["auroc"],
            "n_pca_components": metrics["n_pca_components"],
            "pca_explained_variance": metrics["pca_explained_variance"],
            "train_rows": metrics["train_rows"],
            "test_rows": metrics["test_rows"],
            "train_subjects": metrics["train_subjects"],
            "test_subjects": metrics["test_subjects"],
        }
        fold_rows.append(fold_record)
        pred_frames.append(pred_df)

        fold_dir = branch_dir / f"fold_{fold}"
        fold_dir.mkdir(parents=True, exist_ok=True)
        pd.Series(metrics).drop(labels=["confusion_matrix", "classification_report"]).to_csv(
            fold_dir / "metrics.csv"
        )
        pd.DataFrame(metrics["confusion_matrix"]).to_csv(
            fold_dir / "confusion_matrix.csv",
            index=False,
            header=False,
        )
        (fold_dir / "classification_report.txt").write_text(metrics["classification_report"])
        pred_df.to_csv(fold_dir / "test_predictions.csv", index=False)

    fold_df = pd.DataFrame(fold_rows).sort_values("fold")
    fold_df.to_csv(branch_dir / "fold_metrics.csv", index=False)
    pd.concat(pred_frames, ignore_index=True).to_csv(branch_dir / "all_test_predictions.csv", index=False)

    summary = {
        "branch": branch,
        "config": config_name,
        "accuracy_mean": float(fold_df["accuracy"].mean()),
        "accuracy_std": float(fold_df["accuracy"].std(ddof=1)),
        "f1_macro_mean": float(fold_df["f1_macro"].mean()),
        "f1_macro_std": float(fold_df["f1_macro"].std(ddof=1)),
        "auroc_mean": float(fold_df["auroc"].mean()),
        "auroc_std": float(fold_df["auroc"].std(ddof=1)),
        "mean_pca_components": float(fold_df["n_pca_components"].mean()),
        "mean_pca_explained_variance": (
            float(fold_df["pca_explained_variance"].dropna().mean())
            if fold_df["pca_explained_variance"].notna().any()
            else np.nan
        ),
    }
    pd.Series(summary).to_csv(branch_dir / "summary.csv")
    return summary


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    summaries = []
    for branch in BRANCHES:
        for config_name, n_components, use_agegap in CONFIGS:
            print(f"Running branch={branch} config={config_name}")
            summaries.append(run_branch_config(branch, config_name, n_components, use_agegap))

    summary_df = pd.DataFrame(summaries).sort_values(["branch", "config"])
    summary_df.to_csv(OUT_DIR / "summary.csv", index=False)
    (OUT_DIR / "summary.json").write_text(summary_df.to_json(orient="records", indent=2))
    print(summary_df.to_string(index=False))


if __name__ == "__main__":
    main()

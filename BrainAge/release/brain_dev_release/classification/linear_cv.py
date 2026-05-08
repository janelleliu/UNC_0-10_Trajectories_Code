#!/usr/bin/env python3
"""Subject-level linear classification for BrainDev release datasets.

This is a path-configurable release version of the March 2026 linear
classification workflow. It expects a single dataset CSV with subject-level
folding and supports the same feature modes used in the analysis code:

* with_agegap
* without_agegap
* random_feature
* pca5_with_agegap
* pca5_without_agegap
* pca5_random_feature
"""

from __future__ import annotations

import argparse
import json
import os
import random
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.calibration import CalibratedClassifierCV
from sklearn.decomposition import PCA
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression, RidgeClassifier, SGDClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, f1_score, roc_auc_score
from sklearn.model_selection import StratifiedKFold
from sklearn.preprocessing import StandardScaler
from sklearn.svm import LinearSVC


warnings.filterwarnings("ignore")

FC_PREFIXES = ["Elocal_", "Enodal_", "Gradient1_", "Gradient2_", "McosSim2_", "Str_"]
FEATURE_MODE_CHOICES = [
    "with_agegap",
    "without_agegap",
    "random_feature",
    "pca5_with_agegap",
    "pca5_without_agegap",
    "pca5_random_feature",
]

LINEAR_MODELS = {
    "logistic_l2": lambda seed: LogisticRegression(
        penalty="l2", C=1.0, solver="lbfgs", max_iter=5000, random_state=seed, class_weight="balanced"
    ),
    "logistic_l1": lambda seed: LogisticRegression(
        penalty="l1", C=0.1, solver="saga", max_iter=5000, random_state=seed, class_weight="balanced"
    ),
    "logistic_en": lambda seed: LogisticRegression(
        penalty="elasticnet",
        C=0.5,
        l1_ratio=0.5,
        solver="saga",
        max_iter=5000,
        random_state=seed,
        class_weight="balanced",
    ),
    "ridge": lambda seed: RidgeClassifier(alpha=1.0, class_weight="balanced"),
    "ridge_a10": lambda seed: RidgeClassifier(alpha=10.0, class_weight="balanced"),
    "linear_svc": lambda seed: CalibratedClassifierCV(
        LinearSVC(C=0.5, max_iter=10000, random_state=seed, class_weight="balanced"), cv=3
    ),
    "sgd_log": lambda seed: SGDClassifier(
        loss="log_loss", penalty="l2", alpha=0.001, max_iter=5000, random_state=seed, class_weight="balanced"
    ),
    "sgd_hinge": lambda seed: SGDClassifier(
        loss="hinge", penalty="l2", alpha=0.001, max_iter=5000, random_state=seed, class_weight="balanced"
    ),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dataset-csv", default=None, help="Dataset CSV. If omitted, use --data-dir/--branch.")
    parser.add_argument("--data-dir", default="demo_data/classification", help="Directory containing branch/dataset.csv.")
    parser.add_argument("--branch", default="ndd", choices=["ndd", "ndd_mpd"], help="Branch used with --data-dir.")
    parser.add_argument("--feature-mode", choices=FEATURE_MODE_CHOICES, default="pca5_with_agegap")
    parser.add_argument("--n-folds", type=int, default=5)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--models", nargs="+", default=["logistic_l2", "ridge", "sgd_log"])
    parser.add_argument("--output-dir", default="demo_outputs/classification")
    parser.add_argument("--no-balance", action="store_true", help="Disable SMOTE/RandomOverSampler balancing.")
    return parser.parse_args()


def set_seed(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
    os.environ["PYTHONHASHSEED"] = str(seed)


def resolve_dataset_path(args: argparse.Namespace) -> Path:
    if args.dataset_csv:
        return Path(args.dataset_csv)
    return Path(args.data_dir) / args.branch / "dataset.csv"


def load_dataset(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    required = {"Subjects", "Class", "AgeGap"}
    missing = sorted(required - set(df.columns))
    if missing:
        raise ValueError(f"Dataset CSV is missing required columns: {missing}")
    df["Class"] = pd.to_numeric(df["Class"], errors="coerce").astype(int)
    if "AgeYear" in df.columns:
        df["AgeYear"] = pd.to_numeric(df["AgeYear"], errors="coerce").astype(int)
    df["AgeGap"] = pd.to_numeric(df["AgeGap"], errors="coerce")
    return df


def get_fc_columns(df: pd.DataFrame) -> list[str]:
    cols = [col for col in df.columns if any(col.startswith(prefix) for prefix in FC_PREFIXES)]
    if not cols:
        raise ValueError(f"No FC feature columns found. Expected prefixes: {FC_PREFIXES}")
    return cols


def create_subject_folds(df: pd.DataFrame, n_folds: int, seed: int) -> tuple[pd.DataFrame, int]:
    subject_df = (
        df[["Subjects", "Class"]]
        .drop_duplicates()
        .sort_values(["Class", "Subjects"])
        .reset_index(drop=True)
    )
    min_class = int(subject_df["Class"].value_counts().min())
    effective_folds = max(2, min(int(n_folds), min_class))
    splitter = StratifiedKFold(n_splits=effective_folds, shuffle=True, random_state=seed)
    subject_df["Fold"] = -1
    for fold_id, (_, test_idx) in enumerate(splitter.split(np.zeros((len(subject_df), 1)), subject_df["Class"])):
        subject_df.loc[test_idx, "Fold"] = fold_id

    fold_map = dict(zip(subject_df["Subjects"], subject_df["Fold"]))
    out = df.copy()
    out["Fold"] = out["Subjects"].map(fold_map).astype(int)
    return out, effective_folds


def build_matrices(
    train_df: pd.DataFrame,
    test_df: pd.DataFrame,
    feature_mode: str,
    seed: int,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    fc_cols = get_fc_columns(train_df)
    use_pca5 = feature_mode.startswith("pca5_")
    aux_mode = feature_mode[5:] if use_pca5 else feature_mode

    if use_pca5:
        imputer = SimpleImputer(strategy="median")
        scaler = StandardScaler()
        n_components = max(1, min(5, len(fc_cols), len(train_df) - 1))
        pca = PCA(n_components=n_components, svd_solver="full")

        train_fc = imputer.fit_transform(train_df[fc_cols])
        test_fc = imputer.transform(test_df[fc_cols])
        train_fc = scaler.fit_transform(train_fc)
        test_fc = scaler.transform(test_fc)
        train_fc = pca.fit_transform(train_fc)
        test_fc = pca.transform(test_fc)
        pca_cols = [f"PCA{i + 1}" for i in range(n_components)]
        train_X = pd.DataFrame(train_fc, columns=pca_cols, index=train_df.index)
        test_X = pd.DataFrame(test_fc, columns=pca_cols, index=test_df.index)
    else:
        train_X = train_df[fc_cols].copy()
        test_X = test_df[fc_cols].copy()

    if aux_mode == "with_agegap":
        train_X["AgeGap"] = pd.to_numeric(train_df["AgeGap"], errors="coerce")
        test_X["AgeGap"] = pd.to_numeric(test_df["AgeGap"], errors="coerce")
    elif aux_mode == "random_feature":
        train_agegap = pd.to_numeric(train_df["AgeGap"], errors="coerce")
        mu = float(train_agegap.mean())
        sigma = float(train_agegap.std(ddof=1))
        rng = np.random.RandomState(seed)
        if np.isfinite(sigma) and sigma > 0:
            train_X["RandomFeature"] = rng.normal(mu, sigma, size=len(train_df))
            test_X["RandomFeature"] = rng.normal(mu, sigma, size=len(test_df))
        else:
            train_X["RandomFeature"] = mu
            test_X["RandomFeature"] = mu

    return train_X, test_X


def sanitize_matrix(train_X: pd.DataFrame, test_X: pd.DataFrame) -> tuple[np.ndarray, np.ndarray]:
    train_X = train_X.replace([np.inf, -np.inf], np.nan)
    test_X = test_X.replace([np.inf, -np.inf], np.nan)
    imputer = SimpleImputer(strategy="median")
    scaler = StandardScaler()
    X_train = scaler.fit_transform(imputer.fit_transform(train_X))
    X_test = scaler.transform(imputer.transform(test_X))
    return X_train, X_test


def balance_training_set(X_train: np.ndarray, y_train: np.ndarray, seed: int, enabled: bool) -> tuple[np.ndarray, np.ndarray, str]:
    if not enabled:
        return X_train, y_train, "disabled"
    try:
        from imblearn.over_sampling import RandomOverSampler, SMOTE

        class_counts = np.bincount(y_train)
        minority = class_counts[class_counts > 0].min()
        if minority <= 1:
            raise ValueError("minority class too small for SMOTE")
        k_neighbors = max(1, min(5, int(minority) - 1))
        smote = SMOTE(random_state=seed, k_neighbors=k_neighbors)
        X_bal, y_bal = smote.fit_resample(X_train, y_train)
        return X_bal, y_bal, f"SMOTE(k={k_neighbors})"
    except Exception:
        try:
            from imblearn.over_sampling import RandomOverSampler

            ros = RandomOverSampler(random_state=seed)
            X_bal, y_bal = ros.fit_resample(X_train, y_train)
            return X_bal, y_bal, "RandomOverSampler"
        except Exception:
            return X_train, y_train, "unavailable"


def predict_score(model, X_test: np.ndarray) -> np.ndarray:
    try:
        proba = model.predict_proba(X_test)
        if proba.ndim == 2 and proba.shape[1] == 2:
            return proba[:, 1]
    except Exception:
        pass
    try:
        decision = model.decision_function(X_test)
        if decision.ndim == 1:
            return decision.astype(float)
    except Exception:
        pass
    return np.full(X_test.shape[0], np.nan)


def evaluate(model, X_test: np.ndarray, y_test: np.ndarray) -> tuple[dict, np.ndarray, np.ndarray]:
    y_pred = model.predict(X_test)
    y_score = predict_score(model, X_test)
    metrics = {
        "accuracy": float(accuracy_score(y_test, y_pred)),
        "f1_macro": float(f1_score(y_test, y_pred, average="macro", zero_division=0)),
        "auroc": np.nan,
        "confusion_matrix": confusion_matrix(y_test, y_pred).tolist(),
        "classification_report": classification_report(y_test, y_pred, digits=4, zero_division=0),
    }
    if np.unique(y_test).shape[0] == 2 and np.isfinite(y_score).all():
        metrics["auroc"] = float(roc_auc_score(y_test, y_score))
    return metrics, y_pred, y_score


def run_model_fold(
    model_name: str,
    train_df: pd.DataFrame,
    test_df: pd.DataFrame,
    feature_mode: str,
    seed: int,
    fold: int,
    balance: bool,
) -> tuple[dict, pd.DataFrame]:
    train_X_df, test_X_df = build_matrices(train_df, test_df, feature_mode, seed + fold)
    X_train, X_test = sanitize_matrix(train_X_df, test_X_df)
    y_train = train_df["Class"].to_numpy()
    y_test = test_df["Class"].to_numpy()
    X_bal, y_bal, balance_name = balance_training_set(X_train, y_train, seed + fold, enabled=balance)

    model = LINEAR_MODELS[model_name](seed + fold)
    model.fit(X_bal, y_bal)
    metrics, y_pred, y_score = evaluate(model, X_test, y_test)

    pred_cols = [col for col in ["ScanKey", "Subjects", "AgeYear", "GASDay", "Class", "Fold"] if col in test_df.columns]
    pred_df = test_df[pred_cols].copy()
    pred_df["Model"] = model_name
    pred_df["PredLabel"] = y_pred
    pred_df["PredScore"] = y_score

    result = {
        "model": model_name,
        "fold": int(fold),
        "accuracy": metrics["accuracy"],
        "f1_macro": metrics["f1_macro"],
        "auroc": metrics["auroc"],
        "balance": balance_name,
        "n_train_rows": int(len(train_df)),
        "n_test_rows": int(len(test_df)),
        "n_features": int(train_X_df.shape[1]),
    }
    return result, pred_df


def main() -> None:
    args = parse_args()
    set_seed(args.seed)
    dataset_path = resolve_dataset_path(args)
    df = load_dataset(dataset_path)
    df, effective_folds = create_subject_folds(df, args.n_folds, args.seed)

    models = [name for name in args.models if name in LINEAR_MODELS]
    if not models:
        raise ValueError(f"No valid models selected. Choices: {sorted(LINEAR_MODELS)}")

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    all_results = []
    all_predictions = []
    for fold in sorted(df["Fold"].unique()):
        train_df = df[df["Fold"] != fold].copy()
        test_df = df[df["Fold"] == fold].copy()
        for model_name in models:
            result, pred_df = run_model_fold(
                model_name=model_name,
                train_df=train_df,
                test_df=test_df,
                feature_mode=args.feature_mode,
                seed=args.seed,
                fold=int(fold),
                balance=not args.no_balance,
            )
            all_results.append(result)
            all_predictions.append(pred_df)
        print(f"[fold {fold}] complete")

    results_df = pd.DataFrame(all_results)
    results_df.to_csv(output_dir / "fold_model_metrics.csv", index=False)
    pd.concat(all_predictions, ignore_index=True).to_csv(output_dir / "all_test_predictions.csv", index=False)

    summary_rows = []
    for model_name, model_df in results_df.groupby("model"):
        summary_rows.append(
            {
                "model": model_name,
                "accuracy_mean": model_df["accuracy"].mean(),
                "accuracy_std": model_df["accuracy"].std(ddof=1),
                "f1_macro_mean": model_df["f1_macro"].mean(),
                "f1_macro_std": model_df["f1_macro"].std(ddof=1),
                "auroc_mean": model_df["auroc"].mean(),
                "auroc_std": model_df["auroc"].std(ddof=1),
            }
        )
    summary_df = pd.DataFrame(summary_rows).sort_values("accuracy_mean", ascending=False)
    summary_df.to_csv(output_dir / "model_summary.csv", index=False)

    metadata = {
        "dataset_csv": str(dataset_path),
        "feature_mode": args.feature_mode,
        "requested_folds": args.n_folds,
        "effective_folds": effective_folds,
        "seed": args.seed,
        "models": models,
        "n_rows": int(len(df)),
        "n_subjects": int(df["Subjects"].nunique()),
    }
    (output_dir / "run_metadata.json").write_text(json.dumps(metadata, indent=2))
    print(summary_df.to_string(index=False))
    print(f"\nWrote classification outputs to {output_dir}")


if __name__ == "__main__":
    main()

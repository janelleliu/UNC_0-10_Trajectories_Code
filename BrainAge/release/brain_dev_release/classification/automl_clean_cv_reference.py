#!/usr/bin/env python3

import argparse
import json
import os
import random
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
from flaml import AutoML
from imblearn.over_sampling import RandomOverSampler, SMOTE
from sklearn.decomposition import PCA
from sklearn.impute import SimpleImputer
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, f1_score, roc_auc_score
from sklearn.model_selection import StratifiedKFold
from sklearn.preprocessing import StandardScaler


warnings.filterwarnings("ignore")

ROOT = Path("/common/lidxxlab/Yifan/BrainDev")
CLASS_DIR = ROOT / "code" / "Classification"
DATA_DIR = CLASS_DIR / "lists" / "clean_cv"
RESULTS_DIR = CLASS_DIR / "automl_results_clean"

ESTIMATORS = ["lgbm", "xgboost", "rf", "extra_tree", "lrl1", "catboost"]
FC_PREFIXES = ["Elocal_", "Enodal_", "Gradient1_", "Gradient2_", "McosSim2_", "Str_"]
FEATURE_MODE_CHOICES = [
    "with_agegap",
    "without_agegap",
    "random_feature",
    "pca5_with_agegap",
    "pca5_without_agegap",
    "pca5_random_feature",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--branch", choices=["ndd", "ndd_mpd"], required=True)
    parser.add_argument(
        "--feature-mode",
        choices=FEATURE_MODE_CHOICES,
        required=True,
    )
    parser.add_argument("--time-budget", type=int, default=180)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--max-folds", type=int, default=None)
    parser.add_argument("--results-root", default="automl_results_clean")
    parser.add_argument("--seed-subdir", action="store_true")
    return parser.parse_args()


def set_seed(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
    os.environ["PYTHONHASHSEED"] = str(seed)


def load_dataset(branch: str) -> pd.DataFrame:
    path = DATA_DIR / branch / "dataset.csv"
    df = pd.read_csv(path)
    df["AgeYear"] = pd.to_numeric(df["AgeYear"], errors="coerce").astype(int)
    df["Fold"] = pd.to_numeric(df["Fold"], errors="coerce").astype(int)
    df["Class"] = pd.to_numeric(df["Class"], errors="coerce").astype(int)
    return df


def resolve_results_root(results_root: str) -> Path:
    path = Path(results_root)
    if path.is_absolute():
        return path
    return CLASS_DIR / path


def get_run_dir(results_root: Path, branch: str, feature_mode: str, seed: int, seed_subdir: bool) -> Path:
    run_dir = results_root / branch / feature_mode
    if seed_subdir:
        run_dir = run_dir / f"seed_{seed}"
    return run_dir


def get_fc_columns(df: pd.DataFrame) -> list[str]:
    return [col for col in df.columns if any(col.startswith(prefix) for prefix in FC_PREFIXES)]


def make_inner_split(train_df: pd.DataFrame, seed: int) -> tuple[pd.DataFrame, pd.DataFrame]:
    subject_df = train_df[["Subjects", "Class"]].drop_duplicates().sort_values(["Class", "Subjects"])
    min_class = subject_df["Class"].value_counts().min()
    n_splits = max(2, min(5, int(min_class)))
    splitter = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=seed)

    X = np.zeros((len(subject_df), 1))
    y = subject_df["Class"].to_numpy()
    train_idx, val_idx = next(splitter.split(X, y))

    train_subjects = set(subject_df.iloc[train_idx]["Subjects"])
    val_subjects = set(subject_df.iloc[val_idx]["Subjects"])
    return (
        train_df[train_df["Subjects"].isin(train_subjects)].copy(),
        train_df[train_df["Subjects"].isin(val_subjects)].copy(),
    )


def build_matrices(
    train_df: pd.DataFrame,
    val_df: pd.DataFrame,
    test_df: pd.DataFrame,
    feature_mode: str,
    seed: int,
) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    fc_cols = get_fc_columns(train_df)

    use_pca5 = feature_mode.startswith("pca5_")
    aux_mode = feature_mode[5:] if use_pca5 else feature_mode

    if use_pca5:
        imputer = SimpleImputer(strategy="median")
        scaler = StandardScaler()
        pca = PCA(n_components=5, svd_solver="full")

        train_fc = imputer.fit_transform(train_df[fc_cols])
        val_fc = imputer.transform(val_df[fc_cols])
        test_fc = imputer.transform(test_df[fc_cols])

        train_fc = scaler.fit_transform(train_fc)
        val_fc = scaler.transform(val_fc)
        test_fc = scaler.transform(test_fc)

        train_fc = pca.fit_transform(train_fc)
        val_fc = pca.transform(val_fc)
        test_fc = pca.transform(test_fc)

        pca_cols = [f"PCA{i + 1}" for i in range(train_fc.shape[1])]
        train_X = pd.DataFrame(train_fc, columns=pca_cols, index=train_df.index)
        val_X = pd.DataFrame(val_fc, columns=pca_cols, index=val_df.index)
        test_X = pd.DataFrame(test_fc, columns=pca_cols, index=test_df.index)
    else:
        train_X = train_df[fc_cols].copy()
        val_X = val_df[fc_cols].copy()
        test_X = test_df[fc_cols].copy()

    if aux_mode == "with_agegap":
        for frame, target in [(train_df, train_X), (val_df, val_X), (test_df, test_X)]:
            target["AgeGap"] = pd.to_numeric(frame["AgeGap"], errors="coerce")
    elif aux_mode == "random_feature":
        train_agegap = pd.to_numeric(train_df["AgeGap"], errors="coerce")
        mu = float(train_agegap.mean())
        sigma = float(train_agegap.std(ddof=1))
        if not np.isfinite(sigma):
            sigma = 0.0
        rng = np.random.RandomState(seed)
        for frame, target in [(train_df, train_X), (val_df, val_X), (test_df, test_X)]:
            draws = rng.normal(mu, sigma, size=len(frame)) if sigma > 0 else np.full(len(frame), mu)
            target["RandomFeature"] = draws

    return train_X, val_X, test_X


def sanitize_matrix(train_X: pd.DataFrame, val_X: pd.DataFrame, test_X: pd.DataFrame) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    train_X = train_X.replace([np.inf, -np.inf], np.nan)
    val_X = val_X.replace([np.inf, -np.inf], np.nan)
    test_X = test_X.replace([np.inf, -np.inf], np.nan)

    imputer = SimpleImputer(strategy="median")
    X_train = imputer.fit_transform(train_X)
    X_val = imputer.transform(val_X)
    X_test = imputer.transform(test_X)
    return X_train, X_val, X_test


def balance_training_set(X_train: np.ndarray, y_train: np.ndarray, seed: int) -> tuple[np.ndarray, np.ndarray, str]:
    class_counts = np.bincount(y_train)
    minority = class_counts[class_counts > 0].min()
    k_neighbors = max(1, min(5, minority - 1))
    try:
        if minority <= 1:
            raise ValueError("minority class too small for SMOTE")
        smote = SMOTE(random_state=seed, k_neighbors=k_neighbors)
        X_bal, y_bal = smote.fit_resample(X_train, y_train)
        return X_bal, y_bal, f"SMOTE(k_neighbors={k_neighbors})"
    except Exception:
        ros = RandomOverSampler(random_state=seed)
        X_bal, y_bal = ros.fit_resample(X_train, y_train)
        return X_bal, y_bal, "RandomOverSampler"


def fit_automl(X_train: np.ndarray, y_train: np.ndarray, X_val: np.ndarray, y_val: np.ndarray, time_budget: int, seed: int) -> AutoML:
    automl = AutoML()
    automl.fit(
        X_train=X_train,
        y_train=y_train,
        X_val=X_val,
        y_val=y_val,
        time_budget=time_budget,
        task="classification",
        metric="macro_f1",
        eval_method="holdout",
        estimator_list=ESTIMATORS,
        n_jobs=max(1, int(os.environ.get("SLURM_CPUS_PER_TASK", "1"))),
        seed=seed,
        log_file_name=None,
    )
    return automl


def evaluate(model: AutoML, X_test: np.ndarray, y_test: np.ndarray) -> tuple[dict, np.ndarray, np.ndarray]:
    y_pred = model.predict(X_test)
    proba = None
    try:
        proba = model.predict_proba(X_test)
    except Exception:
        proba = None

    metrics = {
        "accuracy": float(accuracy_score(y_test, y_pred)),
        "f1_macro": float(f1_score(y_test, y_pred, average="macro")),
    }
    pred_score = np.full(len(y_test), np.nan, dtype=float)
    if proba is not None and proba.ndim == 2 and proba.shape[1] == 2:
        metrics["auroc"] = float(roc_auc_score(y_test, proba[:, 1]))
        pred_score = proba[:, 1]
    else:
        metrics["auroc"] = np.nan

    metrics["confusion_matrix"] = confusion_matrix(y_test, y_pred).tolist()
    metrics["classification_report"] = classification_report(y_test, y_pred, digits=4)
    return metrics, y_pred, pred_score


def save_fold_artifacts(
    fold_dir: Path,
    automl: AutoML,
    metrics: dict,
    balance_name: str,
    feature_columns: list[str],
    train_subjects: int,
    val_subjects: int,
    test_subjects: int,
    predictions_df: pd.DataFrame,
) -> None:
    fold_dir.mkdir(parents=True, exist_ok=True)

    pd.Series(
        {
            "accuracy": metrics["accuracy"],
            "f1_macro": metrics["f1_macro"],
            "auroc": metrics["auroc"],
            "balance_method": balance_name,
            "best_estimator": automl.best_estimator,
            "train_subjects": train_subjects,
            "val_subjects": val_subjects,
            "test_subjects": test_subjects,
            "n_features": len(feature_columns),
        }
    ).to_csv(fold_dir / "metrics.csv")

    (fold_dir / "classification_report.txt").write_text(metrics["classification_report"])
    pd.DataFrame(metrics["confusion_matrix"]).to_csv(
        fold_dir / "confusion_matrix.csv", index=False, header=False
    )
    (fold_dir / "best_model.json").write_text(
        json.dumps(
            {
                "best_estimator": automl.best_estimator,
                "best_config": automl.best_config,
                "best_loss": automl.best_loss,
                "features": feature_columns,
            },
            indent=2,
            default=str,
        )
    )
    predictions_df.to_csv(fold_dir / "test_predictions.csv", index=False)


def run_fold(
    df: pd.DataFrame,
    branch: str,
    feature_mode: str,
    fold: int,
    time_budget: int,
    seed: int,
    run_dir: Path,
) -> tuple[dict, pd.DataFrame]:
    test_df = df[df["Fold"] == fold].copy()
    train_outer = df[df["Fold"] != fold].copy()
    train_df, val_df = make_inner_split(train_outer, seed + fold)

    train_X_df, val_X_df, test_X_df = build_matrices(
        train_df=train_df,
        val_df=val_df,
        test_df=test_df,
        feature_mode=feature_mode,
        seed=seed + fold,
    )
    feature_columns = list(train_X_df.columns)
    X_train, X_val, X_test = sanitize_matrix(train_X_df, val_X_df, test_X_df)
    y_train = train_df["Class"].to_numpy()
    y_val = val_df["Class"].to_numpy()
    y_test = test_df["Class"].to_numpy()

    X_bal, y_bal, balance_name = balance_training_set(X_train, y_train, seed + fold)
    automl = fit_automl(X_bal, y_bal, X_val, y_val, time_budget=time_budget, seed=seed + fold)
    metrics, y_pred, pred_score = evaluate(automl, X_test, y_test)

    predictions_df = test_df[["ScanKey", "Subjects", "AgeYear", "GASDay", "Class", "Fold"]].copy()
    predictions_df["Seed"] = seed
    predictions_df["Branch"] = branch
    predictions_df["FeatureMode"] = feature_mode
    predictions_df["PredLabel"] = y_pred
    predictions_df["PredScore"] = pred_score

    fold_dir = run_dir / f"fold_{fold}"
    save_fold_artifacts(
        fold_dir=fold_dir,
        automl=automl,
        metrics=metrics,
        balance_name=balance_name,
        feature_columns=feature_columns,
        train_subjects=train_df["Subjects"].nunique(),
        val_subjects=val_df["Subjects"].nunique(),
        test_subjects=test_df["Subjects"].nunique(),
        predictions_df=predictions_df,
    )

    return {
        "fold": fold,
        "accuracy": metrics["accuracy"],
        "f1_macro": metrics["f1_macro"],
        "auroc": metrics["auroc"],
        "train_rows": len(train_df),
        "val_rows": len(val_df),
        "test_rows": len(test_df),
        "train_subjects": train_df["Subjects"].nunique(),
        "val_subjects": val_df["Subjects"].nunique(),
        "test_subjects": test_df["Subjects"].nunique(),
    }, predictions_df


def main() -> None:
    args = parse_args()
    set_seed(args.seed)

    df = load_dataset(args.branch)
    folds = sorted(df["Fold"].unique())
    if args.max_folds is not None:
        folds = folds[: args.max_folds]

    results_root = resolve_results_root(args.results_root)
    out_dir = get_run_dir(results_root, args.branch, args.feature_mode, args.seed, args.seed_subdir)
    out_dir.mkdir(parents=True, exist_ok=True)

    results = []
    all_predictions = []
    for fold in folds:
        print(f"[{args.branch}/{args.feature_mode}/seed={args.seed}] fold={fold} start")
        fold_result, pred_df = run_fold(
            df=df,
            branch=args.branch,
            feature_mode=args.feature_mode,
            fold=fold,
            time_budget=args.time_budget,
            seed=args.seed,
            run_dir=out_dir,
        )
        results.append(fold_result)
        all_predictions.append(pred_df)
        print(f"[{args.branch}/{args.feature_mode}/seed={args.seed}] fold={fold} metrics={fold_result}")

    results_df = pd.DataFrame(results).sort_values("fold")
    results_df.to_csv(out_dir / "fold_metrics.csv", index=False)
    pd.concat(all_predictions, ignore_index=True).to_csv(out_dir / "all_test_predictions.csv", index=False)

    summary = pd.Series(
        {
            "branch": args.branch,
            "feature_mode": args.feature_mode,
            "seed": args.seed,
            "folds_run": len(results_df),
            "accuracy_mean": results_df["accuracy"].mean(),
            "accuracy_std": results_df["accuracy"].std(ddof=1),
            "f1_macro_mean": results_df["f1_macro"].mean(),
            "f1_macro_std": results_df["f1_macro"].std(ddof=1),
            "auroc_mean": results_df["auroc"].mean(),
            "auroc_std": results_df["auroc"].std(ddof=1),
        }
    )
    summary.to_csv(out_dir / "summary.csv")
    print(summary.to_string())


if __name__ == "__main__":
    main()

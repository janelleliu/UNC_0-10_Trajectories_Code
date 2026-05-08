#!/usr/bin/env python3
"""
SHAP analysis to demonstrate the effect of AgeGap on NDD_MPD classification.
For each seed, trains the best model with 10-fold CV, computes SHAP values,
and reports feature importance rankings.
"""

import os
import random
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
import shap

warnings.filterwarnings("ignore")

from ML_linear_10fold import (
    load_dataset, create_subject_folds, build_matrices, sanitize_matrix,
    balance_training_set, LINEAR_MODELS, get_fc_columns,
)

# Best 10 seeds for PCA5 with_agegap (by accuracy)
PCA5_SEEDS_MODELS = [
    (164, "sgd_hinge"), (86, "sgd_log"), (113, "sgd_log"),
    (23, "sgd_log"), (79, "sgd_hinge"), (37, "sgd_hinge"),
    (78, "sgd_hinge"), (54, "sgd_hinge"), (84, "sgd_log"),
    (155, "sgd_log"),
]

# Best 10 seeds for raw with_agegap (by accuracy)
RAW_SEEDS_MODELS = [
    (113, "sgd_log"), (102, "sgd_hinge"), (89, "sgd_log"),
    (23, "sgd_log"), (18, "linear_svc_C01"), (20, "sgd_hinge"),
    (154, "sgd_log"), (136, "sgd_log"), (160, "logistic_en"),
    (71, "logistic_l2_C01"),
]

N_FOLDS = 10


def get_shap_values_for_seed(df_orig, seed, model_name, feature_mode):
    """Train model with 10-fold CV, compute SHAP values on test sets."""
    random.seed(seed)
    np.random.seed(seed)

    df = create_subject_folds(df_orig, n_folds=N_FOLDS, seed=seed)
    folds = sorted(df["Fold10"].unique())

    all_shap = []
    feature_names = None

    for fold in folds:
        test_df = df[df["Fold10"] == fold].copy()
        train_df = df[df["Fold10"] != fold].copy()

        train_X_df, test_X_df = build_matrices(train_df, test_df, feature_mode, seed + fold)
        if feature_names is None:
            feature_names = list(train_X_df.columns)
        X_train, X_test = sanitize_matrix(train_X_df, test_X_df)
        y_train = train_df["Class"].to_numpy()

        X_bal, y_bal, _ = balance_training_set(X_train, y_train, seed + fold)
        model = LINEAR_MODELS[model_name](seed + fold)
        model.fit(X_bal, y_bal)

        # Use linear SHAP explainer for linear models
        # For CalibratedClassifierCV (linear_svc), use KernelExplainer
        try:
            if hasattr(model, "coef_"):
                explainer = shap.LinearExplainer(model, X_train)
                sv = explainer.shap_values(X_test)
            elif hasattr(model, "calibrated_classifiers_"):
                # CalibratedClassifierCV wrapping LinearSVC
                # Extract the underlying LinearSVC coefficients for pseudo-SHAP
                base = model.calibrated_classifiers_[0].estimator
                if hasattr(base, "coef_"):
                    coef = base.coef_.flatten()
                    sv = X_test * coef[np.newaxis, :]
                else:
                    bg = shap.sample(X_train, min(50, len(X_train)))
                    predict_fn = lambda x: model.predict_proba(x)[:, 1]
                    explainer = shap.KernelExplainer(predict_fn, bg)
                    sv = explainer.shap_values(X_test, nsamples=100)
            else:
                # Fallback: permutation
                explainer = shap.Explainer(model.predict, X_train, feature_names=feature_names)
                sv = explainer(X_test).values
        except Exception as e:
            print(f"    [WARN] seed={seed} fold={fold} SHAP failed: {e}, using coef fallback")
            # For SGD/linear models, use coefficient magnitude as pseudo-SHAP
            if hasattr(model, "coef_"):
                coef = model.coef_.flatten()
                sv = X_test * coef[np.newaxis, :]
            else:
                sv = np.zeros_like(X_test)

        if isinstance(sv, list):
            sv = sv[1]  # binary: class 1

        # Ensure 2D with correct shape
        if sv.ndim == 3:
            sv = sv[:, :, 1]  # (samples, features, classes) -> class 1
        if sv.ndim == 2 and sv.shape[1] != len(feature_names):
            # Might be (features, classes) per sample — take class 1
            if sv.shape[0] == X_test.shape[0] and sv.shape[1] == 2:
                sv = sv[:, 1:2]  # won't work, likely (n_samples, 2) for 2 features
            elif sv.shape == (X_test.shape[0], len(feature_names) * 2):
                # Interleaved classes
                sv = sv[:, 1::2]

        all_shap.append(sv)

    all_shap = np.vstack(all_shap)
    return all_shap, feature_names


def analyze_shap(shap_values, feature_names, label):
    """Compute mean |SHAP| and rank features."""
    mean_abs = np.mean(np.abs(shap_values), axis=0)
    if mean_abs.ndim > 1:
        mean_abs = mean_abs.flatten()
    # Truncate or pad if needed
    n = len(feature_names)
    mean_abs = mean_abs[:n]
    importance = pd.Series(mean_abs, index=feature_names[:len(mean_abs)]).sort_values(ascending=False)

    agegap_rank = None
    agegap_importance = None
    for i, (fname, val) in enumerate(importance.items()):
        if fname in ("AgeGap", "RandomFeature"):
            agegap_rank = i + 1
            agegap_importance = val
            break

    return importance, agegap_rank, agegap_importance


def run_analysis(df, feature_mode, seeds_models, label):
    print(f"\n{'#'*80}")
    print(f"# SHAP Analysis: {label}")
    print(f"# Feature mode: {feature_mode}, {len(seeds_models)} seeds")
    print(f"{'#'*80}")

    all_importances = []
    ranks = []
    importance_vals = []

    for seed, model_name in seeds_models:
        print(f"  Processing seed={seed}, model={model_name}...", flush=True)
        shap_vals, feat_names = get_shap_values_for_seed(df, seed, model_name, feature_mode)
        imp, rank, imp_val = analyze_shap(shap_vals, feat_names, f"seed{seed}")
        all_importances.append(imp)
        ranks.append(rank)
        importance_vals.append(imp_val)

        n_features = len(feat_names)
        target = "AgeGap" if "with_agegap" in feature_mode else "RandomFeature"
        print(f"    {target} rank: {rank}/{n_features}, importance: {imp_val:.6f}")

    # Aggregate across seeds
    imp_df = pd.DataFrame(all_importances)
    mean_imp = imp_df.mean().sort_values(ascending=False)
    std_imp = imp_df.std()

    print(f"\n{'='*70}")
    print(f"AGGREGATED SHAP IMPORTANCE (mean |SHAP| across {len(seeds_models)} seeds)")
    print(f"{'='*70}")
    print(f"{'Rank':>5} {'Feature':>20} {'Mean |SHAP|':>12} {'Std':>10}")
    print("-" * 50)
    for i, (fname, val) in enumerate(mean_imp.items()):
        marker = " <-- " if fname in ("AgeGap", "RandomFeature") else ""
        print(f"{i+1:>5} {fname:>20} {val:>12.6f} {std_imp[fname]:>10.6f}{marker}")

    target = "AgeGap" if "with_agegap" in feature_mode else "RandomFeature"
    print(f"\n  {target} rank across seeds: {ranks}")
    print(f"  Mean rank: {np.mean(ranks):.1f} / {n_features}")
    print(f"  Mean importance: {np.mean(importance_vals):.6f}")

    return mean_imp, ranks


def main():
    df = load_dataset("ndd_mpd")

    # 1. PCA5 with_agegap
    pca5_imp, pca5_ranks = run_analysis(
        df, "pca5_with_agegap", PCA5_SEEDS_MODELS,
        "PCA5 + AgeGap (6 features)")

    # 2. PCA5 random_feature (control)
    pca5_rand_seeds = [(s, m) for s, m in PCA5_SEEDS_MODELS]
    # Need to find best model for random_feature at same seeds
    # Load from results
    ROOT = Path("automl_results_agegap_ablation")
    rn_results = pd.read_csv(ROOT / "ndd_mpd" / "pca5_random_feature" / "all_seed_model_results.csv")
    rn_best = rn_results.loc[rn_results.groupby("seed")["accuracy_mean"].idxmax()].set_index("seed")
    pca5_rand_seeds = [(s, rn_best.loc[s, "model"]) for s, _ in PCA5_SEEDS_MODELS if s in rn_best.index]

    pca5r_imp, pca5r_ranks = run_analysis(
        df, "pca5_random_feature", pca5_rand_seeds,
        "PCA5 + RandomFeature (control, 6 features)")

    # 3. Raw with_agegap
    raw_imp, raw_ranks = run_analysis(
        df, "with_agegap", RAW_SEEDS_MODELS,
        "Raw FC + AgeGap (56 features)")

    # 4. Raw random_feature (control)
    rn_raw = pd.read_csv(ROOT / "ndd_mpd" / "random_feature" / "all_seed_model_results.csv")
    rn_raw_best = rn_raw.loc[rn_raw.groupby("seed")["accuracy_mean"].idxmax()].set_index("seed")
    raw_rand_seeds = [(s, rn_raw_best.loc[s, "model"]) for s, _ in RAW_SEEDS_MODELS if s in rn_raw_best.index]

    raw_r_imp, raw_r_ranks = run_analysis(
        df, "random_feature", raw_rand_seeds,
        "Raw FC + RandomFeature (control, 56 features)")

    # Summary comparison
    print(f"\n{'#'*80}")
    print("# SUMMARY: AgeGap vs RandomFeature SHAP importance")
    print(f"{'#'*80}")
    print(f"\n  PCA5 features (6 total):")
    print(f"    AgeGap mean rank:         {np.mean(pca5_ranks):.1f}/6")
    print(f"    RandomFeature mean rank:  {np.mean(pca5r_ranks):.1f}/6")
    print(f"    AgeGap mean |SHAP|:       {pca5_imp.get('AgeGap', 0):.6f}")
    print(f"    RandomFeature mean |SHAP|:{pca5r_imp.get('RandomFeature', 0):.6f}")

    print(f"\n  Raw features (56 total):")
    print(f"    AgeGap mean rank:         {np.mean(raw_ranks):.1f}/56")
    print(f"    RandomFeature mean rank:  {np.mean(raw_r_ranks):.1f}/56")
    print(f"    AgeGap mean |SHAP|:       {raw_imp.get('AgeGap', 0):.6f}")
    print(f"    RandomFeature mean |SHAP|:{raw_r_imp.get('RandomFeature', 0):.6f}")


if __name__ == "__main__":
    main()

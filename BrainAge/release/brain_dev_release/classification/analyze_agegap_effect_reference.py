#!/usr/bin/env python3
"""
Analyze the effect of AgeGap on classification accuracy.
Compares with_agegap vs without_agegap vs random_feature across seeds.
Uses paired statistical tests since the same seeds produce matched comparisons.
"""

import os
from pathlib import Path

import numpy as np
import pandas as pd
from scipy import stats

ROOT = Path("/common/lidxxlab/Yifan/BrainDev/code/Classification")
ABLATION_DIR = ROOT / "automl_results_agegap_ablation"


def load_best_per_seed(branch: str, feature_mode: str) -> pd.Series:
    """Load results and return best accuracy per seed (across all models)."""
    f = ABLATION_DIR / branch / feature_mode / "all_seed_model_results.csv"
    df = pd.read_csv(f)
    return df.groupby("seed")["accuracy_mean"].max()


def paired_comparison(a: pd.Series, b: pd.Series, name_a: str, name_b: str):
    """Paired t-test and Wilcoxon signed-rank test on matched seeds."""
    common = a.index.intersection(b.index)
    x = a.loc[common].values
    y = b.loc[common].values
    diff = x - y

    t_stat, t_p = stats.ttest_rel(x, y)
    try:
        w_stat, w_p = stats.wilcoxon(diff, alternative="two-sided")
    except ValueError:
        w_stat, w_p = np.nan, np.nan

    return {
        "comparison": f"{name_a} vs {name_b}",
        "n_seeds": len(common),
        f"mean_{name_a}": x.mean(),
        f"mean_{name_b}": y.mean(),
        "mean_diff": diff.mean(),
        "std_diff": diff.std(ddof=1),
        "cohens_d": diff.mean() / diff.std(ddof=1) if diff.std(ddof=1) > 0 else 0,
        "paired_t_stat": t_stat,
        "paired_t_p": t_p,
        "wilcoxon_stat": w_stat,
        "wilcoxon_p": w_p,
        "pct_seeds_a_better": (diff > 0).mean() * 100,
    }


def analyze_branch(branch: str):
    print(f"\n{'#'*70}")
    print(f"# BRANCH: {branch}")
    print(f"{'#'*70}")

    # Raw features comparison
    modes = {}
    for mode in ["with_agegap", "without_agegap", "random_feature",
                  "pca5_with_agegap", "pca5_without_agegap", "pca5_random_feature"]:
        try:
            modes[mode] = load_best_per_seed(branch, mode)
        except FileNotFoundError:
            print(f"  [SKIP] {mode} not found")

    # ---- Summary table ----
    print(f"\n{'='*70}")
    print("SUMMARY: Mean accuracy (best model per seed) across 200 seeds")
    print(f"{'='*70}")
    summary_rows = []
    for mode, series in sorted(modes.items()):
        summary_rows.append({
            "feature_mode": mode,
            "mean_acc": series.mean(),
            "std_acc": series.std(ddof=1),
            "median_acc": series.median(),
            "max_acc": series.max(),
            "min_acc": series.min(),
        })
    summary_df = pd.DataFrame(summary_rows).sort_values("mean_acc", ascending=False)
    print(summary_df.to_string(index=False, float_format="%.4f"))

    # ---- Paired comparisons ----
    print(f"\n{'='*70}")
    print("PAIRED COMPARISONS (same seed = matched pair)")
    print(f"{'='*70}")

    comparisons = []

    # Raw feature comparisons
    if "with_agegap" in modes and "without_agegap" in modes:
        comparisons.append(paired_comparison(
            modes["with_agegap"], modes["without_agegap"],
            "with_agegap", "without_agegap"))
    if "with_agegap" in modes and "random_feature" in modes:
        comparisons.append(paired_comparison(
            modes["with_agegap"], modes["random_feature"],
            "with_agegap", "random_feature"))
    if "without_agegap" in modes and "random_feature" in modes:
        comparisons.append(paired_comparison(
            modes["without_agegap"], modes["random_feature"],
            "without_agegap", "random_feature"))

    # PCA5 comparisons
    if "pca5_with_agegap" in modes and "pca5_without_agegap" in modes:
        comparisons.append(paired_comparison(
            modes["pca5_with_agegap"], modes["pca5_without_agegap"],
            "pca5_with_agegap", "pca5_without_agegap"))
    if "pca5_with_agegap" in modes and "pca5_random_feature" in modes:
        comparisons.append(paired_comparison(
            modes["pca5_with_agegap"], modes["pca5_random_feature"],
            "pca5_with_agegap", "pca5_random_feature"))
    if "pca5_without_agegap" in modes and "pca5_random_feature" in modes:
        comparisons.append(paired_comparison(
            modes["pca5_without_agegap"], modes["pca5_random_feature"],
            "pca5_without_agegap", "pca5_random_feature"))

    # Cross: agegap effect within PCA vs raw
    if "with_agegap" in modes and "pca5_with_agegap" in modes:
        comparisons.append(paired_comparison(
            modes["pca5_with_agegap"], modes["with_agegap"],
            "pca5_with_agegap", "with_agegap"))

    for c in comparisons:
        print(f"\n  {c['comparison']} (n={c['n_seeds']} matched seeds)")
        print(f"    Mean diff: {c['mean_diff']:+.4f} (std={c['std_diff']:.4f})")
        print(f"    Cohen's d: {c['cohens_d']:.3f}")
        print(f"    Paired t-test: t={c['paired_t_stat']:.3f}, p={c['paired_t_p']:.2e}")
        print(f"    Wilcoxon test: W={c['wilcoxon_stat']}, p={c['wilcoxon_p']:.2e}")
        sig = "***" if c['paired_t_p'] < 0.001 else "**" if c['paired_t_p'] < 0.01 else "*" if c['paired_t_p'] < 0.05 else "ns"
        print(f"    Significance: {sig}")
        first_name = c['comparison'].split(' vs ')[0]
        print(f"    % seeds where {first_name} wins: {c['pct_seeds_a_better']:.1f}%")

    # Save
    out_dir = ABLATION_DIR / branch
    out_dir.mkdir(parents=True, exist_ok=True)
    summary_df.to_csv(out_dir / "agegap_effect_summary.csv", index=False)
    pd.DataFrame(comparisons).to_csv(out_dir / "agegap_effect_paired_tests.csv", index=False)

    # ---- Per-model analysis (not just best-per-seed) ----
    print(f"\n{'='*70}")
    print("PER-MODEL ANALYSIS: Average accuracy across all seeds for each model")
    print(f"{'='*70}")

    all_dfs = []
    for mode, _ in sorted(modes.items()):
        f = ABLATION_DIR / branch / mode / "all_seed_model_results.csv"
        df = pd.read_csv(f)
        df["feature_mode"] = mode
        all_dfs.append(df)

    combined = pd.concat(all_dfs, ignore_index=True)
    pivot = combined.groupby(["feature_mode", "model"])["accuracy_mean"].mean().unstack("feature_mode")
    # Show top 5 models
    for mode in sorted(modes.keys()):
        if mode in pivot.columns:
            top5 = pivot[mode].sort_values(ascending=False).head(5)
            print(f"\n  {mode} - Top 5 models:")
            for model, acc in top5.items():
                print(f"    {model}: {acc:.4f}")

    return summary_df, comparisons


def main():
    all_summaries = {}
    for branch in ["ndd", "ndd_mpd"]:
        try:
            summary, comparisons = analyze_branch(branch)
            all_summaries[branch] = summary
        except Exception as e:
            print(f"Error for {branch}: {e}")

    # ---- Cross-branch comparison ----
    if len(all_summaries) == 2:
        print(f"\n{'#'*70}")
        print("# CROSS-BRANCH: AgeGap effect comparison")
        print(f"{'#'*70}")
        for branch, summary in all_summaries.items():
            ag = summary[summary["feature_mode"].str.contains("with_agegap") & ~summary["feature_mode"].str.contains("without")]["mean_acc"].max()
            no_ag = summary[summary["feature_mode"].str.contains("without_agegap")]["mean_acc"].max()
            rand = summary[summary["feature_mode"].str.contains("random_feature")]["mean_acc"].max()
            print(f"\n  {branch}:")
            print(f"    Best with AgeGap:    {ag:.4f}")
            print(f"    Best without AgeGap: {no_ag:.4f}")
            print(f"    Best random feature: {rand:.4f}")
            print(f"    AgeGap boost:        {ag - no_ag:+.4f}")
            print(f"    vs random control:   {ag - rand:+.4f}")


if __name__ == "__main__":
    main()

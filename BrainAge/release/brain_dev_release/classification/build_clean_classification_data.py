#!/usr/bin/env python3

from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.model_selection import StratifiedKFold


ROOT = Path("/common/lidxxlab/Yifan/BrainDev")
CLASS_DIR = ROOT / "code" / "Classification"
COV_DIR = ROOT / "Covariates"
OUT_DIR = CLASS_DIR / "lists" / "clean_cv"

KEY_COLS = ["Subjects", "AgeYear", "GASDay"]
NETWORK_COLS = ["VIS", "SMN", "DAN", "SAL", "LIM", "FPN", "DMN", "SUB"]
AGE_YEARS = {0, 1, 2}
FOLD_SEED = 42
N_SPLITS = 5

FC_SOURCES = {
    "Elocal": ROOT
    / "Harmonized_NetworkFCFeatures"
    / "M_FC_Z_Elocal_8mm2_Harmo_twinPick_All"
    / "M_FC_Z_Elocal_8mm2_Harmo_twinPick_All_0.3mm_notr90_UNC_added_combined.csv",
    "Enodal": ROOT
    / "Harmonized_NetworkFCFeatures"
    / "M_FC_Z_Enodal_8mm2_Harmo_twinPick_All"
    / "M_FC_Z_Enodal_8mm2_Harmo_twinPick_All_0.3mm_notr90_UNC_added_combined.csv",
    "Gradient1": ROOT
    / "Harmonized_NetworkFCFeatures"
    / "M_FC_Z_Gradient1_AlignedToHCP_Harmo_twinPick_All"
    / "M_FC_Z_Gradient1_AlignedToHCP_Harmo_twinPick_All_0.3mm_notr90_UNC_added_combined.csv",
    "Gradient2": ROOT
    / "Harmonized_NetworkFCFeatures"
    / "M_FC_Z_Gradient2_AlignedToHCP_Harmo_twinPick_All"
    / "M_FC_Z_Gradient2_AlignedToHCP_Harmo_twinPick_All_0.3mm_notr90_UNC_added_combined.csv",
    "McosSim2": ROOT
    / "Harmonized_NetworkFCFeatures"
    / "M_FC_Z_McosSim2_Harmo_twinPick_All"
    / "M_FC_Z_McosSim2_Harmo_twinPick_All_0.3mm_notr90_UNC_added_combined.csv",
    "Str": ROOT
    / "Harmonized_NetworkFCFeatures"
    / "M_FC_Z_Str_8mm2_Harmo_twinPick_All"
    / "M_FC_Z_Str_8mm2_Harmo_twinPick_All_0.3mm_notr90_UNC_added_combined.csv",
}

VOTE_FILES = {
    "healthy": CLASS_DIR / "valid_epoch200_vote.csv",
    "AD": CLASS_DIR / "AD_epoch200_vote.csv",
    "AU": CLASS_DIR / "AU_epoch200_vote.csv",
    "MPD": CLASS_DIR / "MPD_epoch200_vote.csv",
}

LIST_FILES = {
    "healthy": COV_DIR / "01246810_Union_full_subject_updated_final_twinPick_32W_Healthy.txt",
    "AD": COV_DIR / "01246810_Union_full_subject_updated_final_twinPick_AD.txt",
    "AU": COV_DIR / "01246810_Union_full_subject_updated_final_twinPick_AU.txt",
    "ADAU": COV_DIR / "01246810_Union_full_subject_updated_final_twinPick_ADAU.txt",
    "MPD": COV_DIR / "01246810_Union_full_subject_updated_final_twinPick_MaternalPD.txt",
}

BRANCH_CONFIG = {
    "ndd": {
        "positive_groups": ["AD", "AU"],
        "positive_subjects_key": "ADAU",
        "label": "NDD",
    },
    "ndd_mpd": {
        "positive_groups": ["AD", "AU", "MPD"],
        "positive_subjects_key": "NDD_MPD",
        "label": "NDD_MPD",
    },
}


def read_subject_list(path: Path) -> set[str]:
    return {line.strip() for line in path.read_text().splitlines() if line.strip()}


def load_fc_table() -> pd.DataFrame:
    merged = None
    for prefix, path in FC_SOURCES.items():
        df = pd.read_csv(path)
        df["AgeYear"] = pd.to_numeric(df["AgeYear"], errors="coerce").astype("Int64")
        df["GASDay"] = pd.to_numeric(df["GASDay"], errors="coerce")
        df = df[df["AgeYear"].isin(AGE_YEARS)].copy()

        rename_map = {col: f"{prefix}_{col}" for col in NETWORK_COLS}
        df = df[KEY_COLS + NETWORK_COLS].rename(columns=rename_map)

        if merged is None:
            merged = df
        else:
            merged = merged.merge(df, on=KEY_COLS, how="inner", validate="one_to_one")

    if merged is None:
        raise RuntimeError("No FC tables were loaded.")

    merged["AgeYear"] = merged["AgeYear"].astype(int)
    merged["GASDay"] = merged["GASDay"].astype(int)
    return merged.sort_values(KEY_COLS).reset_index(drop=True)


def load_vote_file(path: Path, allowed_subjects: set[str]) -> pd.DataFrame:
    df = pd.read_csv(path)
    subject_col = "Subjects" if "Subjects" in df.columns else "Subject"
    df = df.rename(columns={subject_col: "Subjects"})
    df["AgeYear"] = pd.to_numeric(df["AgeYear"], errors="coerce").astype("Int64")
    df = df[df["AgeYear"].isin(AGE_YEARS)].copy()
    df = df[df["Subjects"].isin(allowed_subjects)].copy()

    for col in ["Age", "PredictAge", "ExtPred_0"]:
        df[col] = pd.to_numeric(df[col], errors="coerce")
    df["AgeGap"] = df["PredictAge"] - df["Age"]
    df["VoteSource"] = path.stem

    keep_cols = ["Subjects", "AgeYear", "Age", "PredictAge", "ExtPred_0", "AgeGap", "VoteSource"]
    return df[keep_cols]


def aggregate_votes(vote_frames: list[pd.DataFrame]) -> pd.DataFrame:
    combined = pd.concat(vote_frames, ignore_index=True)
    grouped = (
        combined.groupby(["Subjects", "AgeYear"], as_index=False)
        .agg(
            {
                "Age": "mean",
                "PredictAge": "mean",
                "ExtPred_0": "mean",
                "AgeGap": "mean",
                "VoteSource": lambda vals: "|".join(sorted(set(vals))),
            }
        )
        .rename(columns={"VoteSource": "VoteSources"})
    )
    grouped["VoteSourceCount"] = grouped["VoteSources"].str.count(r"\|") + 1
    grouped["AgeYear"] = grouped["AgeYear"].astype(int)
    return grouped


def assign_subject_folds(subject_df: pd.DataFrame, n_splits: int = N_SPLITS, seed: int = FOLD_SEED) -> pd.DataFrame:
    subject_df = subject_df.sort_values(["Class", "Subjects"]).reset_index(drop=True).copy()
    splitter = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=seed)
    fold_map: dict[str, int] = {}
    X = np.zeros((len(subject_df), 1))
    y = subject_df["Class"].to_numpy()

    for fold_id, (_, test_idx) in enumerate(splitter.split(X, y)):
        for subject in subject_df.iloc[test_idx]["Subjects"]:
            fold_map[subject] = fold_id

    subject_df["Fold"] = subject_df["Subjects"].map(fold_map)
    return subject_df


def summarize_dataset(df: pd.DataFrame, branch: str) -> str:
    subjects_per_class = df.groupby("Class")["Subjects"].nunique().to_dict()
    rows_per_class = df["Class"].value_counts().sort_index().to_dict()
    age_rows = df.groupby(["Class", "AgeYear"]).size().to_dict()
    fold_counts = df.groupby(["Fold", "Class"])["Subjects"].nunique().to_dict()

    lines = [
        f"branch={branch}",
        f"rows={len(df)}",
        f"subjects={df['Subjects'].nunique()}",
        f"subjects_per_class={subjects_per_class}",
        f"rows_per_class={rows_per_class}",
        f"age_rows={age_rows}",
        f"fold_subject_counts={fold_counts}",
    ]
    return "\n".join(lines) + "\n"


def build_branch_dataset(
    branch: str,
    fc_df: pd.DataFrame,
    healthy_subjects: set[str],
    positive_subjects: set[str],
    positive_groups: list[str],
) -> pd.DataFrame:
    healthy_votes = aggregate_votes([load_vote_file(VOTE_FILES["healthy"], healthy_subjects)])
    positive_votes = aggregate_votes(
        [load_vote_file(VOTE_FILES[group], positive_subjects) for group in positive_groups]
    )

    healthy_df = fc_df.merge(healthy_votes, on=["Subjects", "AgeYear"], how="inner")
    healthy_df = healthy_df[healthy_df["Subjects"].isin(healthy_subjects)].copy()
    healthy_df["Class"] = 0
    healthy_df["Cohort"] = "healthy_valid"

    positive_df = fc_df.merge(positive_votes, on=["Subjects", "AgeYear"], how="inner")
    positive_df = positive_df[positive_df["Subjects"].isin(positive_subjects)].copy()
    positive_df["Class"] = 1
    positive_df["Cohort"] = branch

    dataset = pd.concat([healthy_df, positive_df], ignore_index=True)
    dataset = dataset.sort_values(["Class", "Subjects", "AgeYear", "GASDay"]).reset_index(drop=True)

    subject_df = (
        dataset[["Subjects", "Class"]]
        .drop_duplicates()
        .sort_values(["Class", "Subjects"])
        .reset_index(drop=True)
    )
    subject_df = assign_subject_folds(subject_df)
    dataset = dataset.merge(subject_df, on=["Subjects", "Class"], how="left", validate="many_to_one")
    dataset["ScanKey"] = (
        dataset["Subjects"]
        + "_AY"
        + dataset["AgeYear"].astype(str)
        + "_GD"
        + dataset["GASDay"].astype(str)
    )
    return dataset


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    subject_lists = {name: read_subject_list(path) for name, path in LIST_FILES.items()}
    subject_lists["NDD_MPD"] = subject_lists["ADAU"] | subject_lists["MPD"]

    fc_df = load_fc_table()
    master_path = OUT_DIR / "fc_features_age012.csv"
    fc_df.to_csv(master_path, index=False)

    valid_subjects = {
        sid
        for sid in load_vote_file(VOTE_FILES["healthy"], subject_lists["healthy"])["Subjects"].unique()
    }
    healthy_subjects = valid_subjects & subject_lists["healthy"]

    for branch, cfg in BRANCH_CONFIG.items():
        branch_dir = OUT_DIR / branch
        branch_dir.mkdir(parents=True, exist_ok=True)

        positive_subjects = subject_lists[cfg["positive_subjects_key"]]
        dataset = build_branch_dataset(
            branch=branch,
            fc_df=fc_df,
            healthy_subjects=healthy_subjects,
            positive_subjects=positive_subjects,
            positive_groups=cfg["positive_groups"],
        )

        dataset_path = branch_dir / "dataset.csv"
        folds_path = branch_dir / "subject_folds.csv"
        summary_path = branch_dir / "summary.txt"

        dataset.to_csv(dataset_path, index=False)
        dataset[["Subjects", "Class", "Fold"]].drop_duplicates().to_csv(folds_path, index=False)
        summary_path.write_text(summarize_dataset(dataset, branch))

        print(f"[{branch}] wrote dataset: {dataset_path}")
        print(f"[{branch}] wrote subject folds: {folds_path}")
        print(summary_path.read_text().strip())


if __name__ == "__main__":
    main()

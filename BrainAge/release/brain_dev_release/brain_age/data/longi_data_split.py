#!/usr/bin/env python3
import argparse
import pandas as pd
from sklearn.model_selection import train_test_split

def generate_normal_control_guide(
    input_csv: str,
    output_csv: str,
    test_size: float = 0.2,
    random_state: int = 42
):
    # 1. Load
    df = pd.read_csv(input_csv)

    # 2. Filter out any row where "Description" contains "MPRAGE"
    df = df[df['Description'].str.contains('MPRAGE', na=False)]

    # 3. Group by subject and keep only those with >1 visit AND Diagnosis Result==1 for all visits
    grouped = df.groupby('Subject ID')
    eligible_subjects = [
        subject
        for subject, grp in grouped
        if len(grp) > 1 and (grp['Diagnosis Result'] == 1).all()
    ]

    # 4. Split subjects into train/val (80/20)
    train_subjs, val_subjs = train_test_split(
        eligible_subjects,
        test_size=test_size,
        random_state=random_state
    )

    # 5. For each eligible subject, sort visits by Age and emit all (i<j) pairs
    rows = []
    for subject in eligible_subjects:
        visits = (
            grouped.get_group(subject)
                   .sort_values('Age')
                   .reset_index(drop=True)
        )
        ages = visits['Age'].tolist()
        part = 'train' if subject in train_subjs else 'val'
        # all i<j pairs
        for i in range(len(ages)):
            for j in range(i+1, len(ages)):
                rows.append({
                    'subject_ID': subject,
                    'age_visit_1': ages[i],
                    'age_visit_2': ages[j],
                    'split': part
                })

    guide_df = pd.DataFrame(rows)

    # 6. Save to CSV
    guide_df.to_csv(output_csv, index=False)
    print(f"Saved guide with {len(guide_df)} pairs to {output_csv}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Build normal-control guide from ADNI2.csv"
    )
    parser.add_argument(
        '--input', '-i', type=str, default='ADNI2.csv',
        help='Path to original ADNI2.csv'
    )
    parser.add_argument(
        '--output', '-o', type=str, default='normal_control_guide.csv',
        help='Where to write the guide CSV'
    )
    parser.add_argument(
        '--test-size', '-t', type=float, default=0.2,
        help='Fraction of subjects to reserve for validation'
    )
    parser.add_argument(
        '--random-state', '-r', type=int, default=42,
        help='Random seed for reproducibility'
    )
    args = parser.parse_args()
    generate_normal_control_guide(
        args.input,
        args.output,
        test_size=args.test_size,
        random_state=args.random_state
    )

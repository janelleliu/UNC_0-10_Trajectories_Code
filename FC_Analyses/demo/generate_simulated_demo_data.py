import csv
import random
from pathlib import Path

random.seed(260424107)
base = Path(__file__).resolve().parent / 'data'
base.mkdir(parents=True, exist_ok=True)

n_subjects = 60
brain_variables = [
    'net_VIS_score',
    'net_SMN_score',
    'net_DAN_score',
    'net_VAN_score',
    'net_LIM_score',
    'net_FPN_score',
    'net_DMN_score',
    'net_SUB_score',
    'gradient1_score',
    'gradient2_score',
]
behavior_variables = [
    'iq_score',
    'anxiety_score',
    'depression_score',
    'executive_function_score',
]
covariate_variables = [
    'age_years',
    'sex_code',
    'maternal_education_years',
]

subject_rows = []
brain_rows = []
behavior_rows = []
covariate_rows = []
for subject_idx in range(1, n_subjects + 1):
    subject_id = f'SIM{subject_idx:03d}'
    sex = 'M' if subject_idx % 2 else 'F'
    sex_code = 1 if sex == 'M' else 0
    group = ['term', 'preterm', 'maternal_depression'][subject_idx % 3]
    age_years = round(9.5 + random.random(), 3)
    maternal_education = 12 + (subject_idx % 9)

    cognitive_factor = random.gauss(0, 1)
    affective_factor = random.gauss(0, 1)
    gradient_factor = random.gauss(0, 1)
    nuisance_factor = random.gauss(0, 1)

    brain_values = {
        'net_VIS_score': 0.30 * cognitive_factor - 0.10 * affective_factor + 0.20 * gradient_factor + random.gauss(0, 0.55),
        'net_SMN_score': 0.25 * cognitive_factor - 0.05 * affective_factor + 0.10 * gradient_factor + random.gauss(0, 0.55),
        'net_DAN_score': 0.50 * cognitive_factor - 0.10 * affective_factor + random.gauss(0, 0.45),
        'net_VAN_score': 0.20 * cognitive_factor + 0.35 * affective_factor + random.gauss(0, 0.50),
        'net_LIM_score': -0.10 * cognitive_factor + 0.55 * affective_factor + random.gauss(0, 0.45),
        'net_FPN_score': 0.65 * cognitive_factor - 0.20 * affective_factor + 0.15 * gradient_factor + random.gauss(0, 0.42),
        'net_DMN_score': 0.40 * cognitive_factor + 0.25 * affective_factor + 0.20 * gradient_factor + random.gauss(0, 0.45),
        'net_SUB_score': 0.15 * cognitive_factor + 0.15 * nuisance_factor + random.gauss(0, 0.60),
        'gradient1_score': 0.45 * cognitive_factor - 0.15 * affective_factor + 0.55 * gradient_factor + random.gauss(0, 0.45),
        'gradient2_score': -0.10 * cognitive_factor + 0.45 * affective_factor + 0.45 * gradient_factor + random.gauss(0, 0.45),
    }

    group_affective_shift = 0.65 if group == 'maternal_depression' else (0.25 if group == 'preterm' else -0.15)
    behavior_values = {
        'iq_score': 100 + 2.6 * maternal_education + 7.0 * cognitive_factor + 1.5 * gradient_factor + random.gauss(0, 5.5),
        'anxiety_score': 50 + 6.5 * affective_factor + group_affective_shift + random.gauss(0, 4.0),
        'depression_score': 48 + 5.8 * affective_factor - 1.5 * cognitive_factor + group_affective_shift + random.gauss(0, 4.0),
        'executive_function_score': 95 + 8.0 * cognitive_factor - 2.0 * affective_factor + 1.2 * maternal_education + random.gauss(0, 5.0),
    }

    subject_rows.append({
        'subject_id': subject_id,
        'sex': sex,
        'group': group,
    })
    brain_rows.append({'subject_id': subject_id, **{name: round(value, 5) for name, value in brain_values.items()}})
    behavior_rows.append({'subject_id': subject_id, **{name: round(value, 5) for name, value in behavior_values.items()}})
    covariate_rows.append({
        'subject_id': subject_id,
        'age_years': age_years,
        'sex_code': sex_code,
        'maternal_education_years': maternal_education,
    })

with (base / 'simulated_subjects.csv').open('w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['subject_id', 'sex', 'group'])
    writer.writeheader()
    writer.writerows(subject_rows)

with (base / 'simulated_brain_features.csv').open('w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['subject_id'] + brain_variables)
    writer.writeheader()
    writer.writerows(brain_rows)

with (base / 'simulated_behavior.csv').open('w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['subject_id'] + behavior_variables)
    writer.writeheader()
    writer.writerows(behavior_rows)

with (base / 'simulated_covariates.csv').open('w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['subject_id'] + covariate_variables)
    writer.writeheader()
    writer.writerows(covariate_rows)

with (base / 'README_demo_data.md').open('w', newline='') as f:
    f.write('# Simulated demo data\n\n')
    f.write('These files are synthetic and contain no real participant data. They are provided only to demonstrate the CCA-style input format and demo execution.\n\n')
    f.write('- `simulated_subjects.csv`: subject IDs and simple grouping variables.\n')
    f.write('- `simulated_brain_features.csv`: simulated brain-derived variables resembling network, gradient, or trajectory summary features.\n')
    f.write('- `simulated_behavior.csv`: simulated behavioral variables.\n')
    f.write('- `simulated_covariates.csv`: simulated covariates used for optional residualization before CCA.\n\n')
    f.write('The simulation includes shared latent structure between brain and behavior variables so that the CCA demo produces interpretable canonical correlations. The data are not intended to reproduce any manuscript result.\n')

print('Wrote simulated CCA demo data.')

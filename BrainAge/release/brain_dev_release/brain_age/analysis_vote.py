import pandas as pd
import re
import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
import seaborn as sns
import os
from util.metrics import age_to_norm, norm_to_age

def save_and_print(save_path, y_val_pred, y_test_AD_pred, y_test_AU_pred, y_test_MPD_pred,
                  y_val, y_test_AD, y_test_AU, y_test_MPD,
                  val_ageyear, AD_ageyear, AU_ageyear, MPD_ageyear):
    from matplotlib import rcParams
    rcParams.update({'figure.autolayout': True})  # Ensure tight layout globally
    if not os.path.exists(save_path):
        os.makedirs(save_path)
    if not os.path.exists(save_path + '/Prediction'):
        os.makedirs(save_path + '/Prediction')
    if not os.path.exists(save_path + '/Pic'):
        os.makedirs(save_path + '/Pic')

    # Calculate metrics: MAE, RMSE, R2, MAPE for Valid, AD, AU, MPD
    mae_val = np.mean(np.abs(y_val_pred - y_val))
    mae_AD  = np.mean(np.abs(y_test_AD_pred - y_test_AD))
    mae_AU  = np.mean(np.abs(y_test_AU_pred - y_test_AU))
    mae_MPD = np.mean(np.abs(y_test_MPD_pred - y_test_MPD))

    rmse_val = np.sqrt(mean_squared_error(y_val, y_val_pred))
    rmse_AD  = np.sqrt(mean_squared_error(y_test_AD, y_test_AD_pred))
    rmse_AU  = np.sqrt(mean_squared_error(y_test_AU, y_test_AU_pred))
    rmse_MPD = np.sqrt(mean_squared_error(y_test_MPD, y_test_MPD_pred))

    r2_val = r2_score(y_val, y_val_pred)
    r2_AD  = r2_score(y_test_AD, y_test_AD_pred)
    r2_AU  = r2_score(y_test_AU, y_test_AU_pred)
    r2_MPD = r2_score(y_test_MPD, y_test_MPD_pred)

    # Save metrics
    with open(save_path + '/Prediction/metrics.txt', 'w') as f:
        f.write(f'Valid: MAE={mae_val:.4f} RMSE={rmse_val:.4f} R2={r2_val:.4f}\n')
        f.write(f'AD:    MAE={mae_AD:.4f} RMSE={rmse_AD:.4f} R2={r2_AD:.4f}\n')
        f.write(f'AU:    MAE={mae_AU:.4f} RMSE={rmse_AU:.4f} R2={r2_AU:.4f}\n')
        f.write(f'MPD:   MAE={mae_MPD:.4f} RMSE={rmse_MPD:.4f} R2={r2_MPD:.4f}\n')

    '''
    # --- AUROC calculation for AD, AU, MPD detection ---
    from sklearn.metrics import roc_auc_score
    # Define binary labels: 0 for Valid, 1 for AD/AU/MPD
    y_true_AD  = np.array([0]*len(y_val) + [1]*len(y_test_AD))
    y_score_AD = np.concatenate([y_val_pred, y_test_AD_pred])
    auroc_AD = roc_auc_score(y_true_AD, y_score_AD)

    y_true_AU  = np.array([0]*len(y_val) + [1]*len(y_test_AU))
    y_score_AU = np.concatenate([y_val_pred, y_test_AU_pred])
    auroc_AU = roc_auc_score(y_true_AU, y_score_AU)

    y_true_MPD  = np.array([0]*len(y_val) + [1]*len(y_test_MPD))
    y_score_MPD = np.concatenate([y_val_pred, y_test_MPD_pred])
    auroc_MPD = roc_auc_score(y_true_MPD, y_score_MPD)

    with open(save_path + '/Prediction/auroc.txt', 'w') as f:
        f.write(f'AUROC - AD vs Valid:   {auroc_AD:.4f}\n')
        f.write(f'AUROC - AU vs Valid:   {auroc_AU:.4f}\n')
        f.write(f'AUROC - MPD vs Valid:  {auroc_MPD:.4f}\n')

    # Save predictions
    np.save(save_path + '/Prediction/y_val_pred.npy', y_val_pred)
    np.save(save_path + '/Prediction/y_val.npy', y_val)
    np.save(save_path + '/Prediction/y_AD_pred.npy', y_test_AD_pred)
    np.save(save_path + '/Prediction/y_AD.npy', y_test_AD)
    np.save(save_path + '/Prediction/y_AU_pred.npy', y_test_AU_pred)
    np.save(save_path + '/Prediction/y_AU.npy', y_test_AU)
    np.save(save_path + '/Prediction/y_MPD_pred.npy', y_test_MPD_pred)
    np.save(save_path + '/Prediction/y_MPD.npy', y_test_MPD)
    '''
    # Compute BAG (mean error) for bar plot
    bag_val = np.mean(y_val_pred - y_val)
    bag_AD  = np.mean(y_test_AD_pred - y_test_AD)
    bag_AU  = np.mean(y_test_AU_pred - y_test_AU)
    bag_MPD = np.mean(y_test_MPD_pred - y_test_MPD)
    bags = [bag_val, bag_AD, bag_AU, bag_MPD]
    x_labels = ['Valid', 'AD', 'AU', 'MPD']

    sns.barplot(x=x_labels, y=bags)
    # 95% CI error bars
    ci = [
        1.96 * np.std(y_val_pred - y_val),
        1.96 * np.std(y_test_AD_pred - y_test_AD),
        1.96 * np.std(y_test_AU_pred - y_test_AU),
        1.96 * np.std(y_test_MPD_pred - y_test_MPD)
    ]
    plt.errorbar(x=x_labels, y=bags, yerr=ci, fmt='o', color='black')
    plt.ylabel('BAG')
    plt.savefig(save_path + '/Pic/barplot.png')
    plt.clf()

    # plot a box plot for the four test sets
    # 画一个箱线图
    # Box plot of errors
    # Filter out early AgeYears
    exclude_years = {4, 6, 8, 10}
    include_idx_val = [i for i in range(len(y_val)) if val_ageyear[i] not in exclude_years]
    include_idx_AD = [i for i in range(len(y_test_AD)) if AD_ageyear[i] not in exclude_years]
    include_idx_AU = [i for i in range(len(y_test_AU)) if AU_ageyear[i] not in exclude_years]
    include_idx_MPD = [i for i in range(len(y_test_MPD)) if MPD_ageyear[i] not in exclude_years]
    data = [
        y_val_pred[include_idx_val] - y_val[include_idx_val],
        y_test_AD_pred[include_idx_AD] - y_test_AD[include_idx_AD],
        y_test_AU_pred[include_idx_AU] - y_test_AU[include_idx_AU],
        y_test_MPD_pred[include_idx_MPD] - y_test_MPD[include_idx_MPD]
    ]

    # Customize appearance
    flierprops = dict(marker='o', markersize=2, linestyle='none', markerfacecolor='gray', alpha=0.4)
    boxprops = dict(linewidth=1.2)
    medianprops = dict(color='red', linewidth=1.5)
    whiskerprops = dict(linewidth=1.2)
    capprops = dict(linewidth=1.2)

    plt.boxplot(data, flierprops=flierprops, boxprops=boxprops,
                medianprops=medianprops, whiskerprops=whiskerprops, capprops=capprops)

    plt.xticks([1, 2, 3, 4], x_labels, fontsize=10)
    plt.ylabel('Error (Predicted - True)', fontsize=11)
    plt.xlabel('Set', fontsize=11)
    plt.grid(axis='y', linestyle='--', alpha=0.6)
    plt.tight_layout()

    # Add t-tests between Valid and each group (AD, AU, MPD), excluding AgeYear in [0, 1, 2, 4]
    from scipy.stats import ttest_ind
    comparisons = [(0, 1), (0, 2), (0, 3)]
    for i, (i1, i2) in enumerate(comparisons):
        if len(data[i1]) > 1 and len(data[i2]) > 1:
            stat, pval = ttest_ind(data[i1], data[i2], equal_var=False)
            text = f"p={pval:.3f}" if pval >= 0.001 else "p<.001"
            x1, x2 = i1 + 1, i2 + 1
            y = max([max(d) for d in data if len(d) > 0]) + (i+1)*0.5
            h = 0.2
            plt.plot([x1, x1, x2, x2], [y, y+h, y+h, y], lw=1.2, color='black')
            plt.text((x1+x2)*.5, y+h, text, ha='center', va='bottom', fontsize=9)

    plt.savefig(save_path + '/Pic/boxplot_012.png', dpi=300)
    plt.clf()

    # plot a scatter plot with true values and predicted values and regression line for the four test sets
    # Scatter plots with regression lines
    for arr_true, arr_pred, label, color in [
        (y_val, y_val_pred, 'Valid', 'orange'),
        (y_test_AD, y_test_AD_pred, 'AD', 'green'),
        (y_test_AU, y_test_AU_pred, 'AU', 'blue'),
        (y_test_MPD, y_test_MPD_pred, 'MPD', 'purple')
    ]:
        plt.scatter(arr_true, arr_pred, alpha=0.3, s=5, label=label)

    # Regression lines
    for arr_true, arr_pred, label, color in [
        (y_val, y_val_pred, 'Valid', 'orange'),
        (y_test_AD, y_test_AD_pred, 'AD', 'green'),
        (y_test_AU, y_test_AU_pred, 'AU', 'blue'),
        (y_test_MPD, y_test_MPD_pred, 'MPD', 'purple')
    ]:
        coeffs = np.polyfit(arr_true, arr_pred, 1)
        poly = np.poly1d(coeffs)
        plt.plot(arr_true, poly(arr_true), linestyle='--', label=f'{label} Fit')

    # Reference line y = x
    mn = min(np.min(y_val), np.min(y_test_AD), np.min(y_test_AU), np.min(y_test_MPD))
    mx = max(np.max(y_val), np.max(y_test_AD), np.max(y_test_AU), np.max(y_test_MPD))
    plt.plot([mn, mx], [mn, mx], color='black', linewidth=1)

    plt.legend()
    plt.xlabel('True Age')
    plt.ylabel('Predicted Age')
    plt.savefig(save_path + '/Pic/scatter.png')
    plt.clf()

    # --- Boxplot by AgeYear for Validation ---
    # This requires val_ageyear to be available in the current scope.
    # Try to get val_ageyear from the global scope if present.
    try:
        val_ageyear
    except NameError:
        import inspect
        frame = inspect.currentframe()
        while frame:
            if 'val_ageyear' in frame.f_globals:
                val_ageyear = frame.f_globals['val_ageyear']
                break
            frame = frame.f_back
        else:
            raise RuntimeError("val_ageyear not found for boxplot by AgeYear.")
    val_df = pd.DataFrame({'AgeGap': y_val_pred - y_val, 'AgeYear': val_ageyear})
    plt.figure()
    sns.boxplot(
        x='AgeYear',
        y='AgeGap',
        data=val_df,
        flierprops=flierprops,
        boxprops={**boxprops, 'facecolor': 'white'},
        medianprops=medianprops,
        whiskerprops=whiskerprops,
        capprops=capprops
    )
    plt.xlabel('AgeYear')
    plt.ylabel('Age Gap (Predicted - True)')
    plt.title('Validation Age Gap by AgeYear')
    plt.grid(axis='y', linestyle='--', alpha=0.6)
    plt.tight_layout()
    plt.savefig(save_path + '/Pic/val_boxplot_by_ageyear.png', dpi=300)
    plt.clf()

    # --- Summary boxplots by AgeYear with t-tests for all groups ---
    from scipy.stats import mannwhitneyu
    # Try to get AD_ageyear, AU_ageyear, MPD_ageyear from global scope if not present
    try:
        AD_ageyear
    except NameError:
        import inspect
        frame = inspect.currentframe()
        while frame:
            if 'AD_ageyear' in frame.f_globals:
                AD_ageyear = frame.f_globals['AD_ageyear']
                break
            frame = frame.f_back
        else:
            raise RuntimeError("AD_ageyear not found for summary boxplot by AgeYear.")
    try:
        AU_ageyear
    except NameError:
        import inspect
        frame = inspect.currentframe()
        while frame:
            if 'AU_ageyear' in frame.f_globals:
                AU_ageyear = frame.f_globals['AU_ageyear']
                break
            frame = frame.f_back
        else:
            raise RuntimeError("AU_ageyear not found for summary boxplot by AgeYear.")
    try:
        MPD_ageyear
    except NameError:
        import inspect
        frame = inspect.currentframe()
        while frame:
            if 'MPD_ageyear' in frame.f_globals:
                MPD_ageyear = frame.f_globals['MPD_ageyear']
                break
            frame = frame.f_back
        else:
            raise RuntimeError("MPD_ageyear not found for summary boxplot by AgeYear.")

    target_years = sorted(set(val_ageyear))
    colors = ['gray', 'green', 'blue', 'purple']
    group_labels = ['Valid', 'AD', 'AU', 'MPD']

    for yr in target_years:
        val_idx = np.where(val_ageyear == yr)[0]
        ad_idx  = np.where(AD_ageyear == yr)[0]
        au_idx  = np.where(AU_ageyear == yr)[0]
        mpd_idx = np.where(MPD_ageyear == yr)[0]

        data = []
        groups = []
        if len(val_idx) > 0:
            data.append(y_val_pred[val_idx] - y_val[val_idx])
            groups.append('Valid')
        else:
            data.append([])
            groups.append('Valid')

        if len(ad_idx) > 0:
            data.append(y_test_AD_pred[ad_idx] - y_test_AD[ad_idx])
            groups.append('AD')
        else:
            data.append([])
            groups.append('AD')

        if len(au_idx) > 0:
            data.append(y_test_AU_pred[au_idx] - y_test_AU[au_idx])
            groups.append('AU')
        else:
            data.append([])
            groups.append('AU')

        if len(mpd_idx) > 0:
            data.append(y_test_MPD_pred[mpd_idx] - y_test_MPD[mpd_idx])
            groups.append('MPD')
        else:
            data.append([])
            groups.append('MPD')

        plt.figure()
        plt.boxplot(
            data,
            patch_artist=True,
            boxprops={**boxprops, 'facecolor': 'white'},
            flierprops=flierprops,
            medianprops=medianprops,
            whiskerprops=whiskerprops,
            capprops=capprops
        )
        # Patch coloring
        for patch, color in zip(plt.gca().artists, colors):
            patch.set_facecolor(color)
        plt.xticks(ticks=range(1, 5), labels=group_labels)
        plt.ylabel("Age Gap (Pred - True)")
        plt.title(f"Age Gap by Group - AgeYear {yr}")
        plt.grid(axis='y', linestyle='--', alpha=0.6)

        # Perform t-tests and annotate
        comparisons = [(0, 1), (0, 2), (0, 3)]
        for i, (i1, i2) in enumerate(comparisons):
            if len(data[i1]) > 1 and len(data[i2]) > 1:
                stat, pval = mannwhitneyu(data[i1], data[i2], alternative='two-sided')
                text = f"p={pval:.3f}" if pval >= 0.001 else "p<.001"
                x1, x2 = i1 + 1, i2 + 1
                y, h = max(max(d) if len(d) > 0 else 0 for d in data) + (i+1)*0.5, 0.2
                plt.plot([x1, x1, x2, x2], [y, y+h, y+h, y], lw=1.2, color='black')
                plt.text((x1+x2)*.5, y+h, text, ha='center', va='bottom', fontsize=9)

        plt.tight_layout()
        plt.savefig(os.path.join(save_path, f'Pic/summary_boxplot_ageyear{yr}.png'), dpi=300)
        plt.close()

def adjust_predictions_2(HC_Age_Train, PredictTest_Before):
    """
    Adjust predictions by removing the linear trend based on HC_Age_Train.

    Parameters:
    HC_Age_Train (numpy array): The independent variable (age data).
    PredictTest_Before (numpy array): The predicted values before adjustment.

    Returns:
    numpy array: Adjusted predicted values.
    """
    # Step 1: Perform linear fit
    p = np.polyfit(HC_Age_Train, PredictTest_Before, 1)
    q = p[0]  # slope
    qq = p[1]  # intercept

    # 四舍五入
    # Step 2: Calculate the offset

    return np.mean(q), np.mean(qq)

def calc(PredictTest_Before, q, qq):
    Offset = PredictTest_Before - qq
    #keep 1 digit after the decimal point
    PredictTest=np.round(Offset/q, 1)
    return PredictTest

# Define a function to extract numbers from tensor representations
def extract_numbers(text):
    text = str(text)

    # If it's a tensor list format: tensor([x, y, z], device='cuda:0')
    match_list = re.search(r"tensor\(\[([^\]]+)\]", text)
    if match_list:
        return [float(num.strip()) for num in match_list.group(1).split(',')]

    # If it's a single tensor value: tensor(x, device='cuda:0')
    match_single = re.search(r"tensor\(([-+]?\d*\.\d+|\d+)", text)
    if match_single:
        return [float(match_single.group(1))]  # Return as a list for consistency

    return []  # Return an empty list if no match found

def make_list(df):
    df['Age_extracted'] = df['Age'].astype(float)
    df['PredictAge_extracted'] = df['PredictAge'].astype(float)

    flattened_age = []
    flattened_predict_age = []

    for age_val, predict_val in zip(df['Age_extracted'], df['PredictAge_extracted']):
        flattened_age.append(age_val)
        flattened_predict_age.append(predict_val)

    return flattened_age, flattened_predict_age

# === Main execution ===
result_path = '/common/lidxxlab/Yifan/BrainDev/Results/DL/0905_abl_str'

# Load data
val_data = pd.read_csv(os.path.join(result_path, 'valid_epoch300_vote.csv'))
AD_data  = pd.read_csv(os.path.join(result_path, 'AD_epoch300_vote.csv'))
AU_data  = pd.read_csv(os.path.join(result_path, 'AU_epoch300_vote.csv'))
MPD_data = pd.read_csv(os.path.join(result_path, 'MPD_epoch300_vote.csv'))

ref_list = "/common/lidxxlab/Yifan/BrainDev/Processed/WholeSubjectList.csv"

# Directly extract AgeYear from each DataFrame
val_ageyear = val_data['AgeYear'].astype(int).values
AD_ageyear = AD_data['AgeYear'].astype(int).values
AU_ageyear = AU_data['AgeYear'].astype(int).values
MPD_ageyear = MPD_data['AgeYear'].astype(int).values

# Extract lists
y_val, y_val_pred      = make_list(val_data)
y_test_AD, y_test_AD_pred = make_list(AD_data)
y_test_AU, y_test_AU_pred = make_list(AU_data)
y_test_MPD, y_test_MPD_pred = make_list(MPD_data)

# Convert to numpy arrays

y_val_pred = np.array(y_val_pred)
y_val      = np.array(y_val)
y_test_AD_pred = np.array(y_test_AD_pred)
y_test_AD      = np.array(y_test_AD)
y_test_AU_pred = np.array(y_test_AU_pred)
y_test_AU      = np.array(y_test_AU)
y_test_MPD_pred = np.array(y_test_MPD_pred)
y_test_MPD      = np.array(y_test_MPD)

# Convert all data from original units into years
y_val_pred      = y_val_pred / 365.0
y_val           = y_val / 365.0
y_test_AD_pred  = y_test_AD_pred / 365.0
y_test_AD       = y_test_AD / 365.0
y_test_AU_pred  = y_test_AU_pred / 365.0
y_test_AU       = y_test_AU / 365.0
y_test_MPD_pred = y_test_MPD_pred / 365.0
y_test_MPD      = y_test_MPD / 365.0

# Original plots and metrics
orig_dir = os.path.join(result_path, 'original_vote_ssl')
save_and_print(orig_dir, y_val_pred, y_test_AD_pred, y_test_AU_pred, y_test_MPD_pred,
               y_val, y_test_AD, y_test_AU, y_test_MPD,
               val_ageyear, AD_ageyear, AU_ageyear, MPD_ageyear)

# Adjust predictions
q, qq = adjust_predictions_2(y_val, y_val_pred)
y_val_pred_adj    = calc(y_val_pred, q, qq)
y_test_AD_pred_adj = calc(y_test_AD_pred, q, qq)
y_test_AU_pred_adj = calc(y_test_AU_pred, q, qq)
y_test_MPD_pred_adj = calc(y_test_MPD_pred, q, qq)

# Plots after adjustment
adj_dir = os.path.join(result_path, 'adjusted_vote_ssl')
save_and_print(adj_dir, y_val_pred_adj, y_test_AD_pred_adj, y_test_AU_pred_adj, y_test_MPD_pred_adj,
               y_val, y_test_AD, y_test_AU, y_test_MPD,
               val_ageyear, AD_ageyear, AU_ageyear, MPD_ageyear)

## The following block is no longer needed, as AgeYear is extracted directly above
# val_ids = val_data['Subject'].astype(str)
# AD_ids  = AD_data['Subject'].astype(str)
# AU_ids  = AU_data['Subject'].astype(str)
# val_ages = val_data['AgeYear'].astype(int)
# AD_ages = AD_data['AgeYear'].astype(int)
# AU_ages = AU_data['AgeYear'].astype(int)

# Old method (direct extraction from val_list, AD_list, AU_list) removed/commented out
# val_ageyear = val_list['AgeYear'].values
# AD_ageyear = AD_list['AgeYear'].values
# AU_ageyear = AU_list['AgeYear'].values

def compute_mae_by_ageyear(true_ages, pred_ages, ageyears, label, log_file):
    with open(log_file, 'w') as f:
        f.write(f"--- MAE by AgeYear for {label} ---\n")
        print(f"--- MAE by AgeYear for {label} ---")
        target_years = [0, 1, 2, 4, 6, 8, 10]
        for year in target_years:
            indices = np.where(ageyears == year)[0]
            if len(indices) > 0:
                mae = np.mean(np.abs(pred_ages[indices] - true_ages[indices]))
                line = f"AgeYear {year}: MAE = {mae:.4f}"
            else:
                line = f"AgeYear {year}: No data"
            print(line)
            f.write(line + "\n")

# Compute MAE by AgeYear
mae_log_path = os.path.join(result_path, 'original_vote_ssl', 'Prediction', 'mae_by_ageyear.txt')
os.makedirs(os.path.dirname(mae_log_path), exist_ok=True)

compute_mae_by_ageyear(y_val, y_val_pred, val_ageyear, "Valid", mae_log_path)

# Compute BAG statistics
bag_val = y_val_pred - y_val
bag_AD = y_test_AD_pred - y_test_AD
bag_AU = y_test_AU_pred - y_test_AU
bag_MPD = y_test_MPD_pred - y_test_MPD

bag_mean_val, bag_std_val = np.mean(bag_val), np.std(bag_val)
bag_mean_AD, bag_std_AD = np.mean(bag_AD), np.std(bag_AD)
bag_mean_AU, bag_std_AU = np.mean(bag_AU), np.std(bag_AU)
bag_mean_MPD, bag_std_MPD = np.mean(bag_MPD), np.std(bag_MPD)

bag_stats_path = os.path.join(result_path, 'original_vote_ssl', 'Prediction', 'bag_stats.txt')
with open(bag_stats_path, 'w') as f:
    f.write(f'Valid: BAG Mean = {bag_mean_val:.4f}, Std = {bag_std_val:.4f}\n')
    f.write(f'AD:    BAG Mean = {bag_mean_AD:.4f}, Std = {bag_std_AD:.4f}\n')
    f.write(f'AU:    BAG Mean = {bag_mean_AU:.4f}, Std = {bag_std_AU:.4f}\n')
    f.write(f'MPD:   BAG Mean = {bag_mean_MPD:.4f}, Std = {bag_std_MPD:.4f}\n')
print(f"Valid: BAG Mean = {bag_mean_val:.4f}, Std = {bag_std_val:.4f}")
print(f"AD:    BAG Mean = {bag_mean_AD:.4f}, Std = {bag_std_AD:.4f}")
print(f"AU:    BAG Mean = {bag_mean_AU:.4f}, Std = {bag_std_AU:.4f}")
print(f"MPD:   BAG Mean = {bag_mean_MPD:.4f}, Std = {bag_std_MPD:.4f}")

# Compute BAG statistics by AgeYear 6, 8, 10 for Valid, AD, AU, MPD
ageyear_bag_stats_path = os.path.join(result_path, 'original_vote_ssl', 'Prediction', 'bag_by_ageyear.txt')
with open(ageyear_bag_stats_path, 'w') as f:
    f.write("--- BAG Mean and Std by AgeYear (Valid, AD, AU, MPD) ---\n")
    for year in [0, 1, 2, 4, 6, 8, 10]:
        f.write(f"\nAgeYear {year}:\n")

        # Valid
        val_idx = np.where(val_ageyear == year)[0]
        if len(val_idx) > 0:
            bag = y_val_pred[val_idx] - y_val[val_idx]
            mean_bag = np.mean(bag)
            std_bag = np.std(bag)
            f.write(f"  Valid: Mean BAG = {mean_bag:.4f}, Std = {std_bag:.4f}\n")
            print(f"AgeYear {year} - Valid: Mean BAG = {mean_bag:.4f}, Std = {std_bag:.4f}")
        else:
            f.write("  Valid: No data\n")
            print(f"AgeYear {year} - Valid: No data")

        # AD
        ad_idx = np.where(AD_ageyear == year)[0]
        if len(ad_idx) > 0:
            bag = y_test_AD_pred[ad_idx] - y_test_AD[ad_idx]
            mean_bag = np.mean(bag)
            std_bag = np.std(bag)
            f.write(f"  AD:    Mean BAG = {mean_bag:.4f}, Std = {std_bag:.4f}\n")
            print(f"AgeYear {year} - AD:    Mean BAG = {mean_bag:.4f}, Std = {std_bag:.4f}")
        else:
            f.write("  AD:    No data\n")
            print(f"AgeYear {year} - AD:    No data")

        # AU
        au_idx = np.where(AU_ageyear == year)[0]
        if len(au_idx) > 0:
            bag = y_test_AU_pred[au_idx] - y_test_AU[au_idx]
            mean_bag = np.mean(bag)
            std_bag = np.std(bag)
            f.write(f"  AU:    Mean BAG = {mean_bag:.4f}, Std = {std_bag:.4f}\n")
            print(f"AgeYear {year} - AU:    Mean BAG = {mean_bag:.4f}, Std = {std_bag:.4f}")
        else:
            f.write("  AU:    No data\n")
            print(f"AgeYear {year} - AU:    No data")

        # MPD
        mpd_idx = np.where(MPD_ageyear == year)[0]
        if len(mpd_idx) > 0:
            bag = y_test_MPD_pred[mpd_idx] - y_test_MPD[mpd_idx]
            mean_bag = np.mean(bag)
            std_bag = np.std(bag)
            f.write(f"  MPD:   Mean BAG = {mean_bag:.4f}, Std = {std_bag:.4f}\n")
            print(f"AgeYear {year} - MPD:   Mean BAG = {mean_bag:.4f}, Std = {std_bag:.4f}")
        else:
            f.write("  MPD:   No data\n")
            print(f"AgeYear {year} - MPD:   No data")

# Load reference list
ref_df = pd.read_csv(ref_list)

# Define variable list to correlate with predicted age
var_list = [
    'PR_BASC4yr_ANX_T',  'BRIEF4yr_ISCI_T',   'SB4yr_ABIQ_ss',
    'SB_ABIQ_ss_6',      'PR_BASC_ANX_T_6',   'PR_BASC_DEP_T_6',
    'SB_ABIQ_ss_10',     'PR_BASC_ANX_T_10',  'PR_BASC_DEP_T_10'
]

subject_col = val_data['Subject'].astype(str).values
predicted_age = y_val_pred
merged_df = pd.DataFrame({'CaseID': subject_col,
                          'Predicted': predicted_age,
                          'TrueAge': y_val,
                          'AgeYear': val_ageyear})
merged_df['AgeGap'] = merged_df['Predicted'] - merged_df['TrueAge']
ref_df['CaseID'] = ref_df['CaseID'].astype(str)
merged_df = merged_df.merge(ref_df[['CaseID'] + var_list], on='CaseID', how='left')

# Create output directory
corr_plot_dir = os.path.join(result_path, 'correlation_plots_ssl')
os.makedirs(corr_plot_dir, exist_ok=True)

# ---------------- Correlation plots split by AgeYear (0,1,2) ----------------
ageyear_categories = [0, 1, 2, 4, 6, 8, 10]
for yr in ageyear_categories:
    sub_df = merged_df[merged_df['AgeYear'] == yr]
    if sub_df.empty:
        print(f"No data for AgeYear {yr}, skipping.")
        continue

    yr_dir = os.path.join(corr_plot_dir, f'AgeYear_{yr}')
    os.makedirs(yr_dir, exist_ok=True)

    for var in var_list:
        merged_var_df = sub_df[['AgeGap', var]].dropna()
        if merged_var_df.empty:
            print(f"AgeYear {yr}, {var}: No valid data, skipping.")
            continue

        corr_coef = np.corrcoef(merged_var_df['AgeGap'], merged_var_df[var])[0, 1]
        plt.figure()
        plt.scatter(merged_var_df['AgeGap'], merged_var_df[var], alpha=0.6)
        sns.regplot(x='AgeGap', y=var, data=merged_var_df, scatter=False, color='red')
        plt.title(f'AgeYear {yr}: {var} vs Age Gap\nCorrelation: {corr_coef:.3f}')
        plt.xlabel('Age Gap (Predicted - True)')
        plt.ylabel(var)
        plt.savefig(os.path.join(yr_dir, f'{var}_vs_AgeGap_AgeYear{yr}.png'))
        plt.close()

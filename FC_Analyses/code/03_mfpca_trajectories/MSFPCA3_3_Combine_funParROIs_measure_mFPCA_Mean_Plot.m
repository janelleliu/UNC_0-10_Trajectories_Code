clear
clc

%addpath('/media/zhark2/glab1/Haitao/Toolbox_codes/NIfTI_20140122/'); 
%addpath('/media/zhark2/glab1/Haitao/Toolbox_codes/github_repo_myversion/');  %%!!  

%ROIs = {'visualOne','visualTwo','visualThree','DMN','sensoryMotor','auditory','executiveControl','frontoParietalOne','frontoParietalTwo', 'anteriorinsulaR', 'amygdala', 'hippocampus'};  %% 12    %%!!  (omit cerebellum)
%num_ROIs = length(ROIs);

load('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/names_aal.mat');  %%!!  
funPar_aal_inds = load('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/2yr-index-conversion_c.txt');  %%!!  
names_funPar = names_90ROIs(funPar_aal_inds);  %%!!  %%!!  
num_ROIs = length(names_funPar);  %%!!  2yr funPar 278 ROIs

%Colors = [120 18 134; 70 130 180; 0 118 14; 196 58 250; 206 220 46; 230 148 34; 205 62 78; 128 128 128] / 255;  %%!!  RGB values for Yeo 8 networks  (220 248 164) Changed Limbic!!  

measures = {'Str', 'Enodal', 'Elocal', 'McosSim2', 'Gradient1_AlignedToHCP', 'Gradient2_AlignedToHCP'};  %%!!    %%!!  , 'GradientsDispN', 'GradientsDispN2'
measures_str = {'Str', 'Enodal', 'Elocal', 'McosSim', 'Gradient1', 'Gradient2'};  %%!!    %%!!  , 'Dispersion', 'Dispersion-Normalized'
Cov_label = '_Harmo';  %%!!    %%!!  ''(original) / '_Harmo'  %%!!    %%!!  
if strcmp(Cov_label, '')
    ylims = [0,200; 0.15,0.35; 0.2,0.45; 0.15,0.55; -3,3; -3,3];  %%!!    %%!!  ; 1,2; 0.0045,0.0075
elseif strcmp(Cov_label, '_Harmo')
    ylims = [50,200; 0.25,0.35; 0.3,0.5; 0.15,0.6; -3,3; -3,3];  %%!!    %%!!  ; 1,2; 0.0045,0.0075
end

% UNC: UNC 0 1 2 4 6 8 10 in 2yr space
dataset = 'UNC';
FD = '_0.3mm'; %% 0.3mm:'_0.3mm' or 0.5mm:'_0.5mm' 
threshold = 90;  %%  notr90 

for mm=1:length(measures)  %%!!    %%!!  7:8%
    measure = measures{mm};
    measure_str = measures_str{mm};  %%!!  

if ismember(measure, {'Str', 'BC', 'Enodal', 'Elocal'})  %%!!  %%!!  graph measures
    label = '_8mm2';  %%!!    %%!!  _8mm2
else
    label = '';  %%!!  
end

datapath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/MSFPCA3_New_tables_results/mFPCA/GitHub_mFPCA_updated/UNC_tra_mfpca_analyses_ROIs_' measure label Cov_label '_twinPick_All/notebooks/'];  %%!!  %%!!  
%datapath0 = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/MSFPCA3_New_tables_results/M_FC_Z_ROIs_' measure label Cov_label '_twinPick_All/'];  %%!!  %%!!  same
%outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/MSFPCA3_New_tables_results/mFPCA/GitHub_mFPCA_updated/UNC_tra_mfpca_analyses_ROIs_' measure label Cov_label '_twinPick_All/notebooks/'];  %%!!  %%!!  
%if ~exist(outputpath, 'dir')  %%!!  
%    mkdir(outputpath);  %%!!  
%end

FPC_scores = readcell([datapath 'mfpca_tra_ROIs_' measure label Cov_label '_twinPick_All_FPC_scores_1_1.csv'], 'DatetimeType', 'text');  %%!!    %%!!  
X_GAS_Day_Y_STDZ_Mean_mFPCA = readcell([datapath 'mfpca_tra_ROIs_' measure label Cov_label '_twinPick_All_X_GAS_Day_Y_STDZ_Mean_mFPCA_1_1.csv']);  %%!!  
X_GAS_Day_Y_STDZ_FPCs_mFPCA = readcell([datapath 'mfpca_tra_ROIs_' measure label Cov_label '_twinPick_All_X_GAS_Day_Y_STDZ_FPCs_mFPCA_1_1.csv']);  %%!!  
Original_Scale_Var_mean = readcell([datapath 'mfpca_tra_ROIs_' measure label Cov_label '_twinPick_All_Original_Scale_Var_mean_1_1.csv']);  %%!!  
Original_Scale_Var_std = readcell([datapath 'mfpca_tra_ROIs_' measure label Cov_label '_twinPick_All_Original_Scale_Var_std_1_1.csv']);  %%!!  
for ii = 2:139  %%!!  %%!!  
    FPC_scores_ii = readcell([datapath 'mfpca_tra_ROIs_' measure label Cov_label '_twinPick_All_FPC_scores_1_' num2str(ii) '.csv'], 'DatetimeType', 'text');  %%!!    %%!!  
    X_GAS_Day_Y_STDZ_Mean_mFPCA_ii = readcell([datapath 'mfpca_tra_ROIs_' measure label Cov_label '_twinPick_All_X_GAS_Day_Y_STDZ_Mean_mFPCA_1_' num2str(ii) '.csv']);  %%!!  
    X_GAS_Day_Y_STDZ_FPCs_mFPCA_ii = readcell([datapath 'mfpca_tra_ROIs_' measure label Cov_label '_twinPick_All_X_GAS_Day_Y_STDZ_FPCs_mFPCA_1_' num2str(ii) '.csv']);  %%!!  
    Original_Scale_Var_mean_ii = readcell([datapath 'mfpca_tra_ROIs_' measure label Cov_label '_twinPick_All_Original_Scale_Var_mean_1_' num2str(ii) '.csv']);  %%!!  
    Original_Scale_Var_std_ii = readcell([datapath 'mfpca_tra_ROIs_' measure label Cov_label '_twinPick_All_Original_Scale_Var_std_1_' num2str(ii) '.csv']);  %%!!  
    FPC_scores = [FPC_scores, FPC_scores_ii(:, 4:end)];
    X_GAS_Day_Y_STDZ_Mean_mFPCA = [X_GAS_Day_Y_STDZ_Mean_mFPCA, X_GAS_Day_Y_STDZ_Mean_mFPCA_ii(:, 2:end)];
    X_GAS_Day_Y_STDZ_FPCs_mFPCA = [X_GAS_Day_Y_STDZ_FPCs_mFPCA, X_GAS_Day_Y_STDZ_FPCs_mFPCA_ii(:, 2:end)];
    Original_Scale_Var_mean = [Original_Scale_Var_mean, Original_Scale_Var_mean_ii(:, 2:end)];
    Original_Scale_Var_std = [Original_Scale_Var_std, Original_Scale_Var_std_ii(:, 2:end)];
end
writecell(FPC_scores, [datapath 'mfpca_tra_ROIs_' measure label Cov_label '_twinPick_All_FPC_scores_1.csv']);  %%!!    %%!!  
writecell(X_GAS_Day_Y_STDZ_Mean_mFPCA, [datapath 'mfpca_tra_ROIs_' measure label Cov_label '_twinPick_All_X_GAS_Day_Y_STDZ_Mean_mFPCA_1.csv']);  %%!!  
writecell(X_GAS_Day_Y_STDZ_FPCs_mFPCA, [datapath 'mfpca_tra_ROIs_' measure label Cov_label '_twinPick_All_X_GAS_Day_Y_STDZ_FPCs_mFPCA_1.csv']);  %%!!  
writecell(Original_Scale_Var_mean, [datapath 'mfpca_tra_ROIs_' measure label Cov_label '_twinPick_All_Original_Scale_Var_mean_1.csv']);  %%!!  
writecell(Original_Scale_Var_std, [datapath 'mfpca_tra_ROIs_' measure label Cov_label '_twinPick_All_Original_Scale_Var_std_1.csv']);  %%!!  

end


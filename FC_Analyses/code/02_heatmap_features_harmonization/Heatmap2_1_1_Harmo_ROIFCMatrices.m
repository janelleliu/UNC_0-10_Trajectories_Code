clear
clc

addpath('/media/zhark2/glab1/Haitao/Toolbox_codes/NIfTI_20140122/');
mask_file = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-withCerebellum-4mm-mask.nii';
nii = load_nii(mask_file);  %%!!  
W_mask = nii.img;
voxelpar_file = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-4mm-mask-inds.nii.gz';  %%!!    %%!!  
nii = load_nii(voxelpar_file);  %%!!  use this template!!!!    
W_voxelpar = nii.img;

%ROIs = {'visualOne','visualTwo','visualThree','DMN','sensoryMotor','auditory','executiveControl','frontoParietalOne','frontoParietalTwo', 'anteriorinsulaR', 'amygdala', 'hippocampus'};  %% 12    %%!!  (omit cerebellum)
%num_ROIs = length(ROIs);

%ROIs = {'visualOne','visualTwo','sensoryMotor','auditory', 'lOFC','amygdala', 'visualThree','DMN','anteriorinsulaR', 'rDLPFC'};  %% 10    %%!!  %%!!  rAI is very weird; keep using anteriorinsulaR instead
%networks = {'V1N','V2N','SMN','AN', 'OFC','AMYG', 'DAN','DMN','SAL', 'CON'};  %% 10    %%!!  
%num_ROIs = length(ROIs); % copied from glab1/Haitao/Add3networks or Smith10networks; only amygdala is defined and used here  

% UNC: UNC 0 1 2 4 6 8 10 in 2yr space
dataset = 'UNC';

measures = {'FC_Matrices_funPar'};  %%!!    %%!!  run all subjects together: McorrZ / McosSim2 / Str(_8mm2) / Enodal(_8mm2) / Elocal(_8mm2) / TGradient1 / Gradient1_AlignedToHCP / Gradient2_AlignedToHCP 

groups = {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear', 'HCP'};  %%!!  separately
groups_s = {'0', '1', '2', '4', '6', '8', '10', 'HCP'};  %%!!  separately
%clust_thrs = {'15.9', '16.0', '14.6', '12.1', '12.2', '7.3', '6.7'};  %% all groups (N=356/262/212/123/165/153/148); alpha=0.05(bi-sided,NN=1), p=p_thr. FD='_0.3mm',threshold=90   %%!! 

for mm = 1:length(measures)  %%!!  
    measure = measures{mm};
    if ismember(measure, {'Str', 'BC', 'Enodal', 'Elocal'})  %%!!  %%!!  graph measures
        label = '_8mm2';  %%!!    %%!!  _8mm2
    else
        label = '';  %%!!  
    end

%% 0-HCP, separately
for gg = 1:length(groups)

%clust_thr = clust_thrs{gg};
FD = '_0.3mm'; %% 0.3mm:'_0.3mm' or 0.5mm:'_0.5mm' 
%threshold = 90;  %%  notr90 
%p_thr = '0.001';  %% bi-sided 
group = groups{gg};
group_s = groups_s{gg};

load(['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/M_FC_Z_Covs_twinPick_All/M_FC_Z_Covs_twinPick_All_0.3mm_notr90_UNC_' group '.mat']);  %%!!  C as Covariates  
C_P = C(:, [2, 4]);  %%!!  Covs to Preserve: GAS and Sex
C_R = C(:, 9:10);  %%!!  Covs to Remove: DeCov for meanFD and scan-length (centered) here
datapath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/0_ComBat/' measure label '/'];   %%!!    
outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/' measure label '_Harmo/'];   %%!!   %%!!  
if ~exist(outputpath, 'dir')
    mkdir(outputpath);
end
if strcmp(group, 'HCP')
    listpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/lists' FD '/'];
    subjects = importSubjIDs([listpath group_s '_full_subject_updated_final.txt']);  %%!!    All    
else
    listpath = ['/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists' FD '/'];
    subjects = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick.txt']);  %%!!    twinPick All    
end
num_subj = length(subjects);

% De-confounding voxel-wise measure heatmap for each subject  

datadir = [datapath];  %%!!  
outdir = [outputpath group '/'];  %%!!  
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
matrix_size = 278; %% 2yr template: 278 ROIs  %%!!  

infile = [datadir 'data_combat_' measure label '_' group_s '.csv'];
V_All = readmatrix(infile, 'NumHeaderLines', 1, 'OutputType', 'single');
V_All_Harmo = zeros(size(V_All), 'single');
for ii = 1:size(V_All, 1)
    y = V_All(ii, :)';
    [B,~,R] = regress(y, [ones(size(C_P, 1), 1), C_P, C_R]);  %%!!  
    y_Harmo = y - C_R * B(end-size(C_R, 2)+1:end);  %%!!  only remove C_R    OR: %B(1) + C_P * B(2:3) + R;
    V_All_Harmo(ii, :) = y_Harmo;
end
for s=1:num_subj
    subj = subjects{s};
    % measure  
    outfile = [outdir subj '_voxelpar_2yrspace_ROI_FC_Z_matrix_Harmo.1D'];  %%!!    %%!!  
    %if ~exist(outfile, 'file')
        M_Harmo = zeros(matrix_size);
        [rows, cols] = find(triu(ones(matrix_size), 1));  %%!!  matlab is col-major order, while python is row-major order!!!!    
        sortedIndices = sortrows([rows, cols], [1, 2]);
        sortedRows = sortedIndices(:, 1);
        sortedCols = sortedIndices(:, 2);  %%!!  either change here or use an index file previously in python!!!!    
        M_Harmo(sub2ind(size(M_Harmo), sortedRows, sortedCols)) = V_All_Harmo(:, s);
        M_Harmo = M_Harmo + M_Harmo';
        M_Harmo(eye(matrix_size) == 1) = Inf;  %%!!  %%!!  
        dlmwrite(outfile, M_Harmo, 'delimiter', '\t');  %%!!  
    %end
end

if strcmp(group, 'HCP')
    outfile_mean1 = [outputpath group '_mean_FC_M_Harmo.1D'];  %%!!  matrix
else
    outfile_mean1 = [outputpath group '_mean_twinPick_32W_Healthy_FC_M_Harmo.1D'];  %%!!  matrix
end
%if ~exist(outfile_mean1, 'file')
    if strcmp(group_s, 'HCP')
        subjects = importSubjIDs([listpath group_s '_full_subject_updated_final.txt']);  %%!!  HCP
    else
        subjects = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_32W_Healthy.txt']);  %%!!    %%!!  Normal  
    end
    num_s = length(subjects);
    M_mean = zeros(matrix_size);
    for ss = 1:num_s
        subj = subjects{ss};
        outfile = [outdir subj '_voxelpar_2yrspace_ROI_FC_Z_matrix_Harmo.1D'];  %%!!    %%!!  
        M = load(outfile);
        M_mean = M_mean + M;
    end
    M_mean = M_mean / num_s; %% 
    dlmwrite(outfile_mean1, M_mean, 'delimiter', '\t');  %%!!  
%end

end

end

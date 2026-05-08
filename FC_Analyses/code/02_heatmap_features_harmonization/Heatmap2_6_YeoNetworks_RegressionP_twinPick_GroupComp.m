clear
clc

mask_inds_file = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-4mm-mask-inds.nii.gz'; %%    %%!!  %%!!  MUST USE MASK!!!!    
nii_mask_inds = load_nii(mask_inds_file);
W_mask_inds = nii_mask_inds.img;

maskfile = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-Yeo8Net-4mm-mask-inds.nii.gz']; % Yeo 8 networks
nii_mask = load_nii(maskfile);
W_mask = nii_mask.img;

ROIs = {'Visual', 'Somatomotor', 'Dorsal-A', 'Ventral-A', 'Limbic', 'Frontoparietal', 'Default', 'Subcortical'};  %% 8    %%!!  %%!!  Yeo 8 networks (Ventral Attention is Salience)
networks = {'VIS', 'SMN', 'DAN', 'SAL', 'LIM', 'FPN', 'DMN', 'SUB'};  %% 8    %%!!  updated!!  
num_ROIs = length(ROIs); % 

Colors = [120 18 134; 70 130 180; 0 118 14; 196 58 250; 220 248 164; 230 148 34; 205 62 78; 128 128 128] / 255;  %%!!  RGB values for Yeo 8 networks  

graph_label = '_8mm2';  %%!!    %%!!  _funPar or _8mm or _8mm2  %%!!    %%!!  
%measures = {'PeakFre', 'RMSSD', 'Iron', 'McorrZ', 'Str', 'BC', 'Enodal', 'Elocal',  'PeakFre1', 'Str1', 'BC1', 'Enodal1', 'Elocal1',  'Iron1'};  %%!!    %%!!  
%ylims = [0.02,0.06; 0.3,1.1; -10,18; 0.1,0.55; 15,45; 50,400; 0.15,0.35; 0.1,0.22; 0.02,0.06; 10,55; 100,350; 0.3,0.6; 0.5,0.8; -18,10];  %%!!    %%!!  
measures = {'Str', 'Enodal', 'Elocal', 'McosSim2', 'Gradient1_AlignedToHCP', 'Gradient2_AlignedToHCP'};  %%!!    %%!!    %%!!  , 'GradientsDispN', 'GradientsDispN2'
Cov_label = '_Harmo';  %%!!    %%!!  ''(original) / '_Harmo'  %%!!    %%!!  _Harmo for barplots and tests
if strcmp(Cov_label, '')
    ylims = [0,200; 0.15,0.35; 0.2,0.45; 0.15,0.6; -3,3; -3,3];  %%!!    %%!!    %%!!  ; 1.5,3.5; 0.005,0.008
    groups = {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear'};  %%!!  , 'HCP'
    groups_s = {'0', '1', '2', '4', '6', '8', '10'};  %%!!  , 'HCP'
elseif strcmp(Cov_label, '_Harmo')
    ylims = [50,200; 0.25,0.35; 0.3,0.5; 0.15,0.6; -3,3; -3,3];  %%!!    %%!!    %%!!  ; 1.5,3.5; 0.005,0.008
    groups = {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear'};  %%!!  , 'HCP'
    groups_s = {'0', '1', '2', '4', '6', '8', '10'};  %%!!  , 'HCP'
end

for mm=5:6%1:length(measures)  %%!!    %%!!  
    measure = measures{mm};

if ismember(measure, {'Str', 'BC', 'Enodal', 'Elocal',  'Str1', 'BC1', 'Enodal1', 'Elocal1'})  %%!!  %%!!  graph measures
    label = graph_label;  %%!!  
else
    label = '';  %%!!  
end

datapath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/barplots_results/' measure label Cov_label '/'];  %%!!    %%!!  
outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/barplots_results_GroupComp/' measure label Cov_label '/'];  %%!!    %%!!  
if ~exist(outputpath, 'dir')
    mkdir(outputpath);
end
listpath = ['/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists_0.3mm/'];
covpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/M_FC_Z_Covs_twinPick_All/'];

for gg = 1:length(groups)
    group = groups{gg};
    group_s = groups_s{gg};
    demo_file = [listpath 'WholeSubjectList_All_Final_849Subjects_updated_preprocessing_20240718.xlsx'];  %%!!  
    [~,~,data] = xlsread(demo_file);
    subjects_all = data(2:end, 1);  %%!!  
    Medu_all = cell2mat(data(2:end, 94));  %%!!  
    [subjects_all, inds_all] = sort(subjects_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
    Medu_all = Medu_all(inds_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
    subjects_twinPick_All = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick.txt']);  %%!!    %%!!  All  
    subjects_twinPick_Normal = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_32W_Healthy.txt']);  %%!!    %%!!  Normal  
    subjects_twinPick_NDD = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_ADAU.txt']);  %%!!    %%!!  NDD  
    subjects_twinPick_MPD = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_MaternalPD.txt']);  %%!!    %%!!  MPD  
    subjects_twinPick_UNNM = union(subjects_twinPick_Normal, subjects_twinPick_NDD);
    subjects_twinPick_UNNM = union(subjects_twinPick_UNNM, subjects_twinPick_MPD);  %%!!  Union of Normal/NDD/MPD
    Medu_twinPick_UNNM = Medu_all(ismember(subjects_all, subjects_twinPick_UNNM));  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
    subjects_twinPick_UNNM_withMedu = subjects_twinPick_UNNM(~isnan(Medu_twinPick_UNNM));  %%!!  Union of Normal/NDD/MPD & with Medu  %%!!  
    Medu_twinPick_UNNM_withMedu = Medu_all(ismember(subjects_all, subjects_twinPick_UNNM_withMedu));  %%!!    %%!!  
    Medu_twinPick_UNNM_withMedu = Medu_twinPick_UNNM_withMedu - mean(Medu_twinPick_UNNM_withMedu);  %%!!    %%!!  centered
    NDD_twinPick_UNNM_withMedu = double(ismember(subjects_twinPick_UNNM_withMedu, subjects_twinPick_NDD));  %%!!    %%!!  categorized
    MPD_twinPick_UNNM_withMedu = double(ismember(subjects_twinPick_UNNM_withMedu, subjects_twinPick_MPD));  %%!!    %%!!  categorized
    cov_file = [covpath 'M_FC_Z_Covs_twinPick_All_0.3mm_notr90_UNC_' group '.mat'];
    load(cov_file);  %%!!  C as categorized/centered GAB+GAS+BW+Sex +Scanner+MeanFD+ScanLength
    C = C(:, 1:4);  %%!!  C as categorized/centered GAB+GAS+BW+Sex for subjects_twinPick_All
    C_twinPick_UNNM_withMedu = C(ismember(subjects_twinPick_All, subjects_twinPick_UNNM_withMedu), :);  %%!!    %%!!  categorized/centered GAB+GAS+BW+Sex for subjects_twinPick_UNNM_withMedu
    C_twinPick_UNNM_withMedu = [C_twinPick_UNNM_withMedu, Medu_twinPick_UNNM_withMedu, NDD_twinPick_UNNM_withMedu, MPD_twinPick_UNNM_withMedu];  %%!!    %%!!  All covs for cross-sectional regression test (except for intercept 1+)
    
    infile = [datapath measure label '_Mean_twinPick_Heatmap_' group Cov_label '.mat'];  %%!!  All
    load(infile);
    measures_network_twinPick_UNNM_withMedu = measures_network(ismember(subjects_twinPick_All, subjects_twinPick_UNNM_withMedu), :);  %%!!  
    Bs_NDD = zeros(1, num_ROIs);
    Ps_NDD = zeros(1, num_ROIs);
    Bs_MPD = zeros(1, num_ROIs);
    Ps_MPD = zeros(1, num_ROIs);
    alpha = 0.05;  %%!!  
    for rr = 1:num_ROIs
        y_twinPick_UNNM_withMedu = measures_network_twinPick_UNNM_withMedu(:, rr);  %%!!  
        %[B,~,R] = regress(y_twinPick_UNNM_withMedu, [ones(size(C_twinPick_UNNM_withMedu, 1), 1), C_twinPick_UNNM_withMedu]);  %%!!    %%!!  
        mdl = fitlm(C_twinPick_UNNM_withMedu, y_twinPick_UNNM_withMedu);  %%!!    %%!!  regress doesn't output individual p values; use fitlm instead, no need to include ones
        Bs_NDD(rr) = mdl.Coefficients.Estimate(7);  %%!!    %%!!  NDD
        Ps_NDD(rr) = mdl.Coefficients.pValue(7);  %%!!    %%!!  NDD
        Bs_MPD(rr) = mdl.Coefficients.Estimate(8);  %%!!    %%!!  MPD
        Ps_MPD(rr) = mdl.Coefficients.pValue(8);  %%!!    %%!!  MPD
    end
    Hs_NDD = Ps_NDD <= alpha;
    Ps_NDD_FDR = mafdr(Ps_NDD, 'BHFDR', true);
    Hs_NDD_FDR = Ps_NDD_FDR <= alpha;
    Hs_MPD = Ps_MPD <= alpha;
    Ps_MPD_FDR = mafdr(Ps_MPD, 'BHFDR', true);
    Hs_MPD_FDR = Ps_MPD_FDR <= alpha;
    outfile = [outputpath measure label '_Mean_twinPick_Normal_NDD_MPD_Network_RegressionP_' group Cov_label '.mat'];  %%!!    %%!!  Normal-NDD/-MPD    
    save(outfile, 'ROIs', 'networks', 'subjects_twinPick_UNNM_withMedu', 'measures_network_twinPick_UNNM_withMedu', 'C_twinPick_UNNM_withMedu', 'Bs_NDD', 'Ps_NDD', 'Hs_NDD', 'Ps_NDD_FDR', 'Hs_NDD_FDR', 'Bs_MPD', 'Ps_MPD', 'Hs_MPD', 'Ps_MPD_FDR', 'Hs_MPD_FDR');  %%!!    %%!!  
    
end

end


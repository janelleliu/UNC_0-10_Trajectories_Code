clear
clc

groups = {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear'};  %%!!  , 'HCP'
groups_s = {'0', '1', '2', '4', '6', '8', '10'};  %%!!  , 'HCP'

measure = 'FC_Matrices_funPar';  %%!!  %%!!  FC_Matrices_funPar / 
if ismember(measure, {'Str', 'BC', 'Enodal', 'Elocal'})  %%!!  %%!!  graph measures
    label = '_8mm2';  %%!!  
else
    label = '';  %%!!  
end
Cov_label = '_Harmo';  %%!!    %%!!  ''(original) / '_Harmo'  %%!!    %%!!  _Harmo for barplots and tests

datapath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/' measure label Cov_label '/'];  %%!!    %%!!  
outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/CCA4_M_FC_Z_All_for_CCA_Ages/'];  %%!!    %%!!  
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
    GAAssess10_all = data(2:end, 222);  %%!!    %%!!  
    IQ10_all = cell2mat(data(2:end, 223));  %%!!  
    Anxiety10_all = cell2mat(data(2:end, 224));  %%!!  
    Depression10_all = cell2mat(data(2:end, 225));  %%!!  
    [subjects_all, inds_all] = sort(subjects_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
    Medu_all = Medu_all(inds_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
    GAAssess10_all = GAAssess10_all(inds_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
    IQ10_all = IQ10_all(inds_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
    Anxiety10_all = Anxiety10_all(inds_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
    Depression10_all = Depression10_all(inds_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
    subjects_twinPick_All = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick.txt']);  %%!!    %%!!  All  
    subjects_twinPick_Normal = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_32W_Healthy.txt']);  %%!!    %%!!  Normal  
    subjects_twinPick_NDD = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_ADAU.txt']);  %%!!    %%!!  NDD  
    subjects_twinPick_MPD = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_MaternalPD.txt']);  %%!!    %%!!  MPD  
    cov_file = [covpath 'M_FC_Z_Covs_twinPick_All_0.3mm_notr90_UNC_' group '.mat'];
    load(cov_file);  %%!!  C as categorized/centered GAB+GAS+BW+Sex +Scanner+MeanFD+ScanLength
    CC = C(:, 1:4);  %%!!  CC as categorized/centered GAB+GAS+BW+Sex for subjects_twinPick_All  %%!!  %%!!  
    datadir = [datapath group '/'];
    subjects = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick.txt']);  %%!!    %%!!  All  
    num_subj = length(subjects);
    num_ROIs = 278;  %%!!  2yr funPar  
    measures_feature = zeros(num_subj, num_ROIs*(num_ROIs-1)/2);  %%!!  
    for ss = 1:num_subj
        subj = subjects{ss};
        infile = [datadir subj '_voxelpar_2yrspace_ROI_FC_Z_matrix_Harmo.1D'];  %%!!    %%!!  
        M = load(infile);
        measures_feature(ss, :) = M(triu(true(size(M)), 1));  %%!!  %%!!  
    end
    
    subjects_twinPick_IQ10 = intersect(subjects_twinPick_All, subjects_all(~isnan(IQ10_all)));  %%!!  twinPick with IQ10  %%!!  
    subjects_twinPick_Anxiety10 = intersect(subjects_twinPick_All, subjects_all(~isnan(Anxiety10_all)));  %%!!  twinPick with Anxiety10  %%!!  
    subjects_twinPick_Depression10 = intersect(subjects_twinPick_All, subjects_all(~isnan(Depression10_all)));  %%!!  twinPick with Depression10  %%!!  
    subjects_twinPick_AllBehavior10 = intersect(intersect(subjects_twinPick_IQ10, subjects_twinPick_Anxiety10), subjects_twinPick_Depression10);  %%!!  %%!!  subjects with all 3
    Medu_twinPick_AllBehavior10 = Medu_all(ismember(subjects_all, subjects_twinPick_AllBehavior10));  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
    subjects_twinPick_AllBehavior10_withMedu = subjects_twinPick_AllBehavior10(~isnan(Medu_twinPick_AllBehavior10));  %%!!  with AllBehavior10 & with Medu  %%!!  
    Medu_twinPick_AllBehavior10_withMedu = Medu_all(ismember(subjects_all, subjects_twinPick_AllBehavior10_withMedu));  %%!!    %%!!  
    Medu_twinPick_AllBehavior10_withMedu = Medu_twinPick_AllBehavior10_withMedu - mean(Medu_twinPick_AllBehavior10_withMedu);  %%!!    %%!!  centered
    NDD_twinPick_AllBehavior10_withMedu = double(ismember(subjects_twinPick_AllBehavior10_withMedu, subjects_twinPick_NDD));  %%!!    %%!!  categorized
    MPD_twinPick_AllBehavior10_withMedu = double(ismember(subjects_twinPick_AllBehavior10_withMedu, subjects_twinPick_MPD));  %%!!    %%!!  categorized
    GAAssess10_twinPick_AllBehavior10_withMedu = cell2mat(GAAssess10_all(ismember(subjects_all, subjects_twinPick_AllBehavior10_withMedu)));  %%!!    %%!!  
    GAAssess10_twinPick_AllBehavior10_withMedu = GAAssess10_twinPick_AllBehavior10_withMedu - mean(GAAssess10_twinPick_AllBehavior10_withMedu);  %%!!    %%!!  centered
    C_twinPick_AllBehavior10_withMedu = CC(ismember(subjects_twinPick_All, subjects_twinPick_AllBehavior10_withMedu), :);  %%!!    %%!!  categorized/centered GAB+GAS+BW+Sex for subjects_twinPick_AllBehavior10_withMedu  %%!!  %%!!  
    C_twinPick_AllBehavior10_withMedu = [C_twinPick_AllBehavior10_withMedu, Medu_twinPick_AllBehavior10_withMedu, NDD_twinPick_AllBehavior10_withMedu, MPD_twinPick_AllBehavior10_withMedu, GAAssess10_twinPick_AllBehavior10_withMedu];  %%!!    %%!!  All covs for longitudinal regression test (except for intercept 1+)
    IQ10_twinPick_AllBehavior10_withMedu = IQ10_all(ismember(subjects_all, subjects_twinPick_AllBehavior10_withMedu));  %%!!    %%!!  no need to center
    Anxiety10_twinPick_AllBehavior10_withMedu = Anxiety10_all(ismember(subjects_all, subjects_twinPick_AllBehavior10_withMedu));  %%!!    %%!!  no need to center
    Depression10_twinPick_AllBehavior10_withMedu = Depression10_all(ismember(subjects_all, subjects_twinPick_AllBehavior10_withMedu));  %%!!    %%!!  no need to center
    measures_feature_twinPick_AllBehavior10_withMedu = measures_feature(ismember(subjects_twinPick_All, subjects_twinPick_AllBehavior10_withMedu), :);  %%!!  
    X = measures_feature_twinPick_AllBehavior10_withMedu;  %%!!  
    Y = [IQ10_twinPick_AllBehavior10_withMedu, Anxiety10_twinPick_AllBehavior10_withMedu, Depression10_twinPick_AllBehavior10_withMedu];  %%!!  %%!!  
    C = C_twinPick_AllBehavior10_withMedu;  %%!!  
    outdir = [outputpath 'AllBehavior10_' measure label Cov_label '_' group '/data/'];  %%!!  %%!!  
    if ~exist(outdir, 'dir')
        mkdir(outdir);
    end
    save([outdir 'X.mat'], 'X');
    save([outdir 'Y.mat'], 'Y');
    save([outdir 'C.mat'], 'C');
    
end

% make LabelsX_measure.csv
L = cell(1 + size(X, 2), 4);
L(1, :) = {'Label', 'Category', 'Label_proc', 'Label_bold'};
load('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/names_aal.mat');  %%!!  
funPar_aal_inds = load('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/2yr-index-conversion_c.txt');  %%!!  
names_funPar = names_90ROIs(funPar_aal_inds);  %%!!  %%!!  
M_names_funPar = cell(num_ROIs, num_ROIs);
for rr1=1:num_ROIs
    for rr2=1:num_ROIs
        M_names_funPar{rr1, rr2} = [names_funPar{rr1} '-' names_funPar{rr2}];
    end
end
labelsX = M_names_funPar(triu(true(size(M_names_funPar)), 1));  %%!!  %%!!  
for xx = 1:size(X, 2)
    labelX = labelsX{xx};  %%!!  
    L{1 + xx, 1} = labelX; %% 
    L{1 + xx, 2} = measure; %% network
    L{1 + xx, 3} = labelX; %% 
    L{1 + xx, 4} = labelX; %% 
end
T = array2table(L); %% 
writetable(T, [outputpath 'LabelsX_' measure label Cov_label '.csv'], 'WriteVariableNames', false);  %%!!  %%!!  

% make LabelsY_measure.csv
L = cell(1 + size(Y, 2), 4);
L(1, :) = {'Label', 'Category', 'Label_proc', 'Label_bold'};
labelsY = {'IQ10', 'Anxiety10', 'Depression10'};  %%!!  %%!!  
groupsY = {'Cognition_10YR', 'Emotion_10YR', 'Emotion_10YR'};  %%!!  %%!!  
for yy = 1:size(Y, 2)
    labelY = labelsY{yy};  %%!!  
    groupY = groupsY{yy};  %%!!  
    L{1 + yy, 1} = labelY; %% 
    L{1 + yy, 2} = groupY; %% network
    L{1 + yy, 3} = labelY; %% 
    L{1 + yy, 4} = labelY; %% 
end
T = array2table(L); %% 
writetable(T, [outputpath 'LabelsY_AllBehavior10.csv'], 'WriteVariableNames', false);  %%!!  %%!!  


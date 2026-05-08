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
measures = {'Str', 'Enodal', 'Elocal', 'McosSim2', 'Gradient1_AlignedToHCP', 'Gradient2_AlignedToHCP', 'GradientsDispN', 'GradientsDispN2'};  %%!!    %%!!    %%!!  
measures_str = {'Str', 'Enodal', 'Elocal', 'McosSim', 'Gradient1', 'Gradient2', 'Dispersion', 'Dispersion-Normalized'};  %%!!    %%!!  
Cov_label = '_Harmo';  %%!!    %%!!  ''(original) / '_Harmo'  %%!!    %%!!  _Harmo for barplots and tests
if strcmp(Cov_label, '')
    ylims = [0,200; 0.15,0.35; 0.2,0.45; 0.15,0.6; -3,3; -3,3; 1,2; 0.0045,0.0075];  %%!!    %%!!    %%!!  
    groups = {'01246810_Union'};  %%!!  , 'HCP'
    groups_s = {'01246810_Union'};  %%!!  , 'HCP'
elseif strcmp(Cov_label, '_Harmo')
    ylims = [50,200; 0.25,0.35; 0.3,0.5; 0.15,0.6; -3,3; -3,3; 1,2; 0.0045,0.0075];  %%!!    %%!!    %%!!  
    groups = {'01246810_Union'};  %%!!  , 'HCP'
    groups_s = {'01246810_Union'};  %%!!  , 'HCP'
end

for mm=1:length(measures)  %%!!    %%!!  9:10%
    measure = measures{mm};
    measure_str = measures_str{mm};  %%!!  

if ismember(measure, {'Str', 'BC', 'Enodal', 'Elocal',  'Str1', 'BC1', 'Enodal1', 'Elocal1'})  %%!!  %%!!  graph measures
    label = graph_label;  %%!!  
else
    label = '';  %%!!  
end

datapath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/MSFPCA3_New_tables_results/mFPCA/GitHub_mFPCA_updated/UNC_tra_mfpca_analyses_' measure label Cov_label '_twinPick_All/notebooks/'];  %%!!  %%!!  
outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/MSFPCA3_New_tables_results/mFPCA/mfpca_results_GroupComp_Preterm/' measure label Cov_label '/'];  %%!!    %%!!  
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
    %subjects_twinPick_Normal = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_32W_Healthy.txt']);  %%!!    %%!!  Normal  
    subjects_twinPick_Normal_32W = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_32W_Healthy.txt']);  %%!!    %%!!  Normal 32W  
    subjects_twinPick_Preterm_32W = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_Preterm_32W.txt']);  %%!!    %%!!  Preterm 32W  
    %subjects_twinPick_NDD = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_ADAU.txt']);  %%!!    %%!!  NDD  
    subjects_twinPick_MPD = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_MaternalPD.txt']);  %%!!    %%!!  MPD  
    %subjects_twinPick_UNNM = union(subjects_twinPick_Normal, subjects_twinPick_NDD);
    %subjects_twinPick_UNNM = union(subjects_twinPick_UNNM, subjects_twinPick_MPD);  %%!!  Union of Normal/NDD/MPD
    subjects_twinPick_UNP_32W = union(subjects_twinPick_Normal_32W, subjects_twinPick_Preterm_32W);  %%!!  Union of Normal/Preterm 32W
    Medu_twinPick_UNP_32W = Medu_all(ismember(subjects_all, subjects_twinPick_UNP_32W));  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
    subjects_twinPick_UNP_32W_withMedu = subjects_twinPick_UNP_32W(~isnan(Medu_twinPick_UNP_32W));  %%!!  Union of Normal/Preterm 32W & with Medu  %%!!  
    Medu_twinPick_UNP_32W_withMedu = Medu_all(ismember(subjects_all, subjects_twinPick_UNP_32W_withMedu));  %%!!    %%!!  
    Medu_twinPick_UNP_32W_withMedu = Medu_twinPick_UNP_32W_withMedu - mean(Medu_twinPick_UNP_32W_withMedu);  %%!!    %%!!  centered
    %NDD_twinPick_UNP_32W_withMedu = double(ismember(subjects_twinPick_UNP_32W_withMedu, subjects_twinPick_NDD));  %%!!    %%!!  categorized
    MPD_twinPick_UNP_32W_withMedu = double(ismember(subjects_twinPick_UNP_32W_withMedu, subjects_twinPick_MPD));  %%!!    %%!!  categorized
    cov_file = [covpath 'M_FC_Z_Covs_twinPick_All_0.3mm_notr90_UNC_' group '.mat'];
    load(cov_file);  %%!!  C as categorized/centered GAB+BW+Sex
    Preterm_32W_twinPick_UNP_32W_withMedu = double(ismember(subjects_twinPick_UNP_32W_withMedu, subjects_twinPick_Preterm_32W));  %%!!    %%!!  categorized
    C = C(:, [3]);  %%!!  C as categorized/centered Sex for subjects_twinPick_All
    C_twinPick_UNP_32W_withMedu = C(ismember(subjects_twinPick_All, subjects_twinPick_UNP_32W_withMedu), :);  %%!!    %%!!  categorized/centered Sex for subjects_twinPick_UNP_32W_withMedu
    C_twinPick_UNP_32W_withMedu = [Preterm_32W_twinPick_UNP_32W_withMedu, C_twinPick_UNP_32W_withMedu, Medu_twinPick_UNP_32W_withMedu, MPD_twinPick_UNP_32W_withMedu];  %%!!    %%!!  All covs for longitudinal regression test (except for intercept 1+)
    
    % FPC score 1
    infile = [datapath 'mfpca_tra_' measure label Cov_label '_twinPick_All_FPC_scores_1.csv'];  %%!!  All
    FPC_scores = readcell(infile, 'DatetimeType', 'text');  %%!!    %%!!  
    %FPC_scores_twinPick_All = cell2mat(FPC_scores(2:end, 4:end));  %%!!  
    %FPC_scores_twinPick_Normal = cell2mat(FPC_scores(ismember(FPC_scores(:, 2), subjects_twinPick_Normal), 4:end));  %%!!  Normal
    %FPC_scores_twinPick_Normal_mean_ref =  mean(FPC_scores_twinPick_Normal, 1);  %%!!  Normal mean reference
    FPC_scores_twinPick_UNP_32W_withMedu = cell2mat(FPC_scores(ismember(FPC_scores(:, 2), subjects_twinPick_UNP_32W_withMedu), 4:end));  %%!!  
    n_FPC = size(FPC_scores_twinPick_UNP_32W_withMedu, 2) / num_ROIs;
    FPC_1_scores_twinPick_UNP_32W_withMedu = FPC_scores_twinPick_UNP_32W_withMedu(:, 1:n_FPC:end);  %%!!    %%!!  1/2/3/4  1/2/3/4    
    %{
    norm_num = 2;  %%!!  number of FPCs to use  %%!!  n_FPC / 3 / 2 / 1
    FPC_Dev_scores_twinPick_UNNM_withMedu = zeros(size(FPC_scores_twinPick_UNNM_withMedu, 1), num_ROIs);
    for ss = 1:size(FPC_scores_twinPick_UNNM_withMedu, 1)
        for rr = 1:num_ROIs
            FPC_Dev_scores_twinPick_UNNM_withMedu(ss, rr) = norm(FPC_scores_twinPick_UNNM_withMedu(ss, (rr-1)*n_FPC+1:(rr-1)*n_FPC+norm_num) - FPC_scores_twinPick_Normal_mean_ref(1, (rr-1)*n_FPC+1:(rr-1)*n_FPC+norm_num));  %%!!    %%!!  Deviation norm(distance) from Normal mean reference
        end
    end
    %}
    Bs_Preterm = zeros(1, num_ROIs);
    Ps_Preterm = zeros(1, num_ROIs);
    %Bs_MPD = zeros(1, num_ROIs);
    %Ps_MPD = zeros(1, num_ROIs);
    alpha = 0.05;  %%!!  
    for rr = 1:num_ROIs
        y_twinPick_UNP_32W_withMedu = FPC_1_scores_twinPick_UNP_32W_withMedu(:, rr);  %%!!  1/2/3/4/Dev    
        %[B,~,R] = regress(y_twinPick_UNNM_withMedu, [ones(size(C_twinPick_UNNM_withMedu, 1), 1), C_twinPick_UNNM_withMedu]);  %%!!    %%!!  
        mdl = fitlm(C_twinPick_UNP_32W_withMedu, y_twinPick_UNP_32W_withMedu);  %%!!    %%!!  regress doesn't output individual p values; use fitlm instead, no need to include ones
        Bs_Preterm(rr) = mdl.Coefficients.Estimate(2);  %%!!    %%!!  Preterm
        Ps_Preterm(rr) = mdl.Coefficients.pValue(2);  %%!!    %%!!  Preterm
        %Bs_MPD(rr) = mdl.Coefficients.Estimate(7);  %%!!    %%!!  MPD
        %Ps_MPD(rr) = mdl.Coefficients.pValue(7);  %%!!    %%!!  MPD
    end
    Hs_Preterm = Ps_Preterm <= alpha;
    Ps_Preterm_FDR = mafdr(Ps_Preterm, 'BHFDR', true);
    Hs_Preterm_FDR = Ps_Preterm_FDR <= alpha;
    %Hs_MPD = Ps_MPD <= alpha;
    %Ps_MPD_FDR = mafdr(Ps_MPD, 'BHFDR', true);
    %Hs_MPD_FDR = Ps_MPD_FDR <= alpha;
    outfile = [outputpath measure label '_mFPCA_twinPick_Normal_Preterm_32W_FPC_1_scores_RegressionP_' group Cov_label '.mat'];  %%!!    %%!!  Normal-Preterm 32W    1/2/3/4/Dev    
    save(outfile, 'ROIs', 'networks', 'subjects_twinPick_UNP_32W_withMedu', 'FPC_scores_twinPick_UNP_32W_withMedu', 'FPC_1_scores_twinPick_UNP_32W_withMedu', 'C_twinPick_UNP_32W_withMedu', 'Bs_Preterm', 'Ps_Preterm', 'Hs_Preterm', 'Ps_Preterm_FDR', 'Hs_Preterm_FDR');  %%!!    %%!!  1/2/3/4/Dev    
    
    for rr = 1:num_ROIs
        ROI = ROIs{rr};
        network = networks{rr};
        y_twinPick_UNP_32W_withMedu = FPC_1_scores_twinPick_UNP_32W_withMedu(:, rr);  %%!!  1/2/3/4/Dev    
        y_twinPick_UNP_32W_withMedu_Normal_32W = y_twinPick_UNP_32W_withMedu(ismember(subjects_twinPick_UNP_32W_withMedu, subjects_twinPick_Normal_32W));
        y_twinPick_UNP_32W_withMedu_Preterm_32W = y_twinPick_UNP_32W_withMedu(ismember(subjects_twinPick_UNP_32W_withMedu, subjects_twinPick_Preterm_32W));
        %y_twinPick_UNP_32W_withMedu_NDD = y_twinPick_UNP_32W_withMedu(ismember(subjects_twinPick_UNP_32W_withMedu, subjects_twinPick_NDD));
        %y_twinPick_UNP_32W_withMedu_MPD = y_twinPick_UNP_32W_withMedu(ismember(subjects_twinPick_UNP_32W_withMedu, subjects_twinPick_MPD));
        figure;
        Violin({y_twinPick_UNP_32W_withMedu_Normal_32W}, 1, 'ShowMean', true);
        Violin({y_twinPick_UNP_32W_withMedu_Preterm_32W}, 2, 'ShowMean', true);
        grouporder = {'Normal-32W', 'Preterm-32W'};
        xticks([1, 2]); %% 
        xticklabels(grouporder);
        ylabel(['FPC 1 scores: ' measure_str ' ' network]);  %%!!  1/2/3/4/Dev    
        xlim([0.5, 2.5]);
        %ylim([0, 3]);  %%!!  
        set(gcf,'Units','pixels','Position',[200 200 560 420]);
        set(gca, 'FontSize', 12, 'FontWeight', 'bold');  %%!!    %%!!  
        saveas(gcf, [outputpath measure label '_mFPCA_twinPick_Normal_Preterm_32W_FPC_1_scores_ViolinPlot_' group Cov_label '_' network '.png']);  %%!!  1/2/3/4/Dev    
        close;    
%         figure;
%         Violin({y_twinPick_UNP_32W_withMedu_Normal_32W}, 1, 'ShowMean', true);
%         Violin({y_twinPick_UNP_32W_withMedu_MPD}, 2, 'ShowMean', true);
%         grouporder = {'Normal', 'MPD'};
%         xticks([1, 2]); %% 
%         xticklabels(grouporder);
%         ylabel(['FPC 1 scores: ' measure_str ' ' network]);  %%!!  1/2/3/4/Dev    
%         xlim([0.5, 2.5]);
%         %ylim([0, 3]);  %%!!  
%         set(gcf,'Units','pixels','Position',[200 200 560 420]);
%         set(gca, 'FontSize', 12, 'FontWeight', 'bold');  %%!!    %%!!  
%         saveas(gcf, [outputpath measure label '_mFPCA_twinPick_Normal_MPD_FPC_1_scores_ViolinPlot_' group Cov_label '_' network '.png']);  %%!!  1/2/3/4/Dev    
%         close;  
    end
    
    % FPC score 2
    infile = [datapath 'mfpca_tra_' measure label Cov_label '_twinPick_All_FPC_scores_1.csv'];  %%!!  All
    FPC_scores = readcell(infile, 'DatetimeType', 'text');  %%!!    %%!!  
    %FPC_scores_twinPick_All = cell2mat(FPC_scores(2:end, 4:end));  %%!!  
    %FPC_scores_twinPick_Normal = cell2mat(FPC_scores(ismember(FPC_scores(:, 2), subjects_twinPick_Normal), 4:end));  %%!!  Normal
    %FPC_scores_twinPick_Normal_mean_ref =  mean(FPC_scores_twinPick_Normal, 1);  %%!!  Normal mean reference
    FPC_scores_twinPick_UNP_32W_withMedu = cell2mat(FPC_scores(ismember(FPC_scores(:, 2), subjects_twinPick_UNP_32W_withMedu), 4:end));  %%!!  
    n_FPC = size(FPC_scores_twinPick_UNP_32W_withMedu, 2) / num_ROIs;
    FPC_2_scores_twinPick_UNP_32W_withMedu = FPC_scores_twinPick_UNP_32W_withMedu(:, 2:n_FPC:end);  %%!!    %%!!  1/2/3/4  1/2/3/4    
    %{
    norm_num = 2;  %%!!  number of FPCs to use  %%!!  n_FPC / 3 / 2 / 1
    FPC_Dev_scores_twinPick_UNNM_withMedu = zeros(size(FPC_scores_twinPick_UNNM_withMedu, 1), num_ROIs);
    for ss = 1:size(FPC_scores_twinPick_UNNM_withMedu, 1)
        for rr = 1:num_ROIs
            FPC_Dev_scores_twinPick_UNNM_withMedu(ss, rr) = norm(FPC_scores_twinPick_UNNM_withMedu(ss, (rr-1)*n_FPC+1:(rr-1)*n_FPC+norm_num) - FPC_scores_twinPick_Normal_mean_ref(1, (rr-1)*n_FPC+1:(rr-1)*n_FPC+norm_num));  %%!!    %%!!  Deviation norm(distance) from Normal mean reference
        end
    end
    %}
    Bs_Preterm = zeros(1, num_ROIs);
    Ps_Preterm = zeros(1, num_ROIs);
    %Bs_MPD = zeros(1, num_ROIs);
    %Ps_MPD = zeros(1, num_ROIs);
    alpha = 0.05;  %%!!  
    for rr = 1:num_ROIs
        y_twinPick_UNP_32W_withMedu = FPC_2_scores_twinPick_UNP_32W_withMedu(:, rr);  %%!!  1/2/3/4/Dev    
        %[B,~,R] = regress(y_twinPick_UNNM_withMedu, [ones(size(C_twinPick_UNNM_withMedu, 1), 1), C_twinPick_UNNM_withMedu]);  %%!!    %%!!  
        mdl = fitlm(C_twinPick_UNP_32W_withMedu, y_twinPick_UNP_32W_withMedu);  %%!!    %%!!  regress doesn't output individual p values; use fitlm instead, no need to include ones
        Bs_Preterm(rr) = mdl.Coefficients.Estimate(2);  %%!!    %%!!  Preterm
        Ps_Preterm(rr) = mdl.Coefficients.pValue(2);  %%!!    %%!!  Preterm
        %Bs_MPD(rr) = mdl.Coefficients.Estimate(7);  %%!!    %%!!  MPD
        %Ps_MPD(rr) = mdl.Coefficients.pValue(7);  %%!!    %%!!  MPD
    end
    Hs_Preterm = Ps_Preterm <= alpha;
    Ps_Preterm_FDR = mafdr(Ps_Preterm, 'BHFDR', true);
    Hs_Preterm_FDR = Ps_Preterm_FDR <= alpha;
    %Hs_MPD = Ps_MPD <= alpha;
    %Ps_MPD_FDR = mafdr(Ps_MPD, 'BHFDR', true);
    %Hs_MPD_FDR = Ps_MPD_FDR <= alpha;
    outfile = [outputpath measure label '_mFPCA_twinPick_Normal_Preterm_32W_FPC_2_scores_RegressionP_' group Cov_label '.mat'];  %%!!    %%!!  Normal-Preterm 32W    1/2/3/4/Dev    
    save(outfile, 'ROIs', 'networks', 'subjects_twinPick_UNP_32W_withMedu', 'FPC_scores_twinPick_UNP_32W_withMedu', 'FPC_2_scores_twinPick_UNP_32W_withMedu', 'C_twinPick_UNP_32W_withMedu', 'Bs_Preterm', 'Ps_Preterm', 'Hs_Preterm', 'Ps_Preterm_FDR', 'Hs_Preterm_FDR');  %%!!    %%!!  1/2/3/4/Dev    
    
    for rr = 1:num_ROIs
        ROI = ROIs{rr};
        network = networks{rr};
        y_twinPick_UNP_32W_withMedu = FPC_2_scores_twinPick_UNP_32W_withMedu(:, rr);  %%!!  1/2/3/4/Dev    
        y_twinPick_UNP_32W_withMedu_Normal_32W = y_twinPick_UNP_32W_withMedu(ismember(subjects_twinPick_UNP_32W_withMedu, subjects_twinPick_Normal_32W));
        y_twinPick_UNP_32W_withMedu_Preterm_32W = y_twinPick_UNP_32W_withMedu(ismember(subjects_twinPick_UNP_32W_withMedu, subjects_twinPick_Preterm_32W));
        %y_twinPick_UNP_32W_withMedu_NDD = y_twinPick_UNP_32W_withMedu(ismember(subjects_twinPick_UNP_32W_withMedu, subjects_twinPick_NDD));
        %y_twinPick_UNP_32W_withMedu_MPD = y_twinPick_UNP_32W_withMedu(ismember(subjects_twinPick_UNP_32W_withMedu, subjects_twinPick_MPD));
        figure;
        Violin({y_twinPick_UNP_32W_withMedu_Normal_32W}, 1, 'ShowMean', true);
        Violin({y_twinPick_UNP_32W_withMedu_Preterm_32W}, 2, 'ShowMean', true);
        grouporder = {'Normal-32W', 'Preterm-32W'};
        xticks([1, 2]); %% 
        xticklabels(grouporder);
        ylabel(['FPC 2 scores: ' measure_str ' ' network]);  %%!!  1/2/3/4/Dev    
        xlim([0.5, 2.5]);
        %ylim([0, 3]);  %%!!  
        set(gcf,'Units','pixels','Position',[200 200 560 420]);
        set(gca, 'FontSize', 12, 'FontWeight', 'bold');  %%!!    %%!!  
        saveas(gcf, [outputpath measure label '_mFPCA_twinPick_Normal_Preterm_32W_FPC_2_scores_ViolinPlot_' group Cov_label '_' network '.png']);  %%!!  1/2/3/4/Dev    
        close;    
%         figure;
%         Violin({y_twinPick_UNP_32W_withMedu_Normal_32W}, 1, 'ShowMean', true);
%         Violin({y_twinPick_UNP_32W_withMedu_MPD}, 2, 'ShowMean', true);
%         grouporder = {'Normal', 'MPD'};
%         xticks([1, 2]); %% 
%         xticklabels(grouporder);
%         ylabel(['FPC 2 scores: ' measure_str ' ' network]);  %%!!  1/2/3/4/Dev    
%         xlim([0.5, 2.5]);
%         %ylim([0, 3]);  %%!!  
%         set(gcf,'Units','pixels','Position',[200 200 560 420]);
%         set(gca, 'FontSize', 12, 'FontWeight', 'bold');  %%!!    %%!!  
%         saveas(gcf, [outputpath measure label '_mFPCA_twinPick_Normal_MPD_FPC_2_scores_ViolinPlot_' group Cov_label '_' network '.png']);  %%!!  1/2/3/4/Dev    
%         close;  
    end
    
end

end


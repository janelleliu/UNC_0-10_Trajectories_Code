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
measures_str = {'Str', 'Enodal', 'Elocal', 'McosSim', 'Gradient1', 'Gradient2'};  %%!!    %%!!  , 'Dispersion', 'Dispersion-Normalized'
Cov_label = '_Harmo';  %%!!    %%!!  ''(original) / '_Harmo'  %%!!    %%!!  _Harmo for barplots and tests
if strcmp(Cov_label, '')
    ylims = [0,200; 0.15,0.35; 0.2,0.45; 0.15,0.6; -3,3; -3,3];  %%!!    %%!!    %%!!  ; 1.5,3; 0.005,0.008
    groups = {'01246810_Union'};  %%!!  , 'HCP'
    groups_s = {'01246810_Union'};  %%!!  , 'HCP'
elseif strcmp(Cov_label, '_Harmo')
    ylims = [50,200; 0.25,0.35; 0.3,0.5; 0.15,0.6; -3,3; -3,3];  %%!!    %%!!    %%!!  ; 1.5,3; 0.005,0.008
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
outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/MSFPCA3_New_tables_results/mFPCA/mfpca_results_Predictions/' measure label Cov_label '/'];  %%!!    %%!!  
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
    load(cov_file);  %%!!  C as categorized/centered GAB+BW+Sex
    C = C(:, 1:3);  %%!!  C as categorized/centered GAB+BW+Sex for subjects_twinPick_All
    infile = [datapath 'mfpca_tra_' measure label Cov_label '_twinPick_All_FPC_scores_1.csv'];  %%!!  All
    FPC_scores = readcell(infile, 'DatetimeType', 'text');  %%!!    %%!!  
    %FPC_scores_twinPick_All = cell2mat(FPC_scores(2:end, 4:end));  %%!!  
    %FPC_scores_twinPick_Normal = cell2mat(FPC_scores(ismember(FPC_scores(:, 2), subjects_twinPick_Normal), 4:end));  %%!!  Normal
    %FPC_scores_twinPick_Normal_mean_ref =  mean(FPC_scores_twinPick_Normal, 1);  %%!!  Normal mean reference
    %{
    subjects_twinPick_UNNM = union(subjects_twinPick_Normal, subjects_twinPick_NDD);
    subjects_twinPick_UNNM = union(subjects_twinPick_UNNM, subjects_twinPick_MPD);  %%!!  Union of Normal/NDD/MPD
    Medu_twinPick_UNNM = Medu_all(ismember(subjects_all, subjects_twinPick_UNNM));  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
    subjects_twinPick_UNNM_withMedu = subjects_twinPick_UNNM(~isnan(Medu_twinPick_UNNM));  %%!!  Union of Normal/NDD/MPD & with Medu  %%!!  
    Medu_twinPick_UNNM_withMedu = Medu_all(ismember(subjects_all, subjects_twinPick_UNNM_withMedu));  %%!!    %%!!  
    Medu_twinPick_UNNM_withMedu = Medu_twinPick_UNNM_withMedu - mean(Medu_twinPick_UNNM_withMedu);  %%!!    %%!!  centered
    NDD_twinPick_UNNM_withMedu = double(ismember(subjects_twinPick_UNNM_withMedu, subjects_twinPick_NDD));  %%!!    %%!!  categorized
    MPD_twinPick_UNNM_withMedu = double(ismember(subjects_twinPick_UNNM_withMedu, subjects_twinPick_MPD));  %%!!    %%!!  categorized
    C_twinPick_UNNM_withMedu = C(ismember(subjects_twinPick_All, subjects_twinPick_UNNM_withMedu), :);  %%!!    %%!!  categorized/centered GAB+BW+Sex for subjects_twinPick_UNNM_withMedu
    C_twinPick_UNNM_withMedu = [C_twinPick_UNNM_withMedu, Medu_twinPick_UNNM_withMedu, NDD_twinPick_UNNM_withMedu, MPD_twinPick_UNNM_withMedu];  %%!!    %%!!  All covs for longitudinal regression test (except for intercept 1+)
    FPC_scores_twinPick_UNNM_withMedu = cell2mat(FPC_scores(ismember(FPC_scores(:, 2), subjects_twinPick_UNNM_withMedu), 4:end));  %%!!  
    n_FPC = size(FPC_scores_twinPick_UNNM_withMedu, 2) / num_ROIs;
    FPC_2_scores_twinPick_UNNM_withMedu = FPC_scores_twinPick_UNNM_withMedu(:, 2:n_FPC:end);  %%!!    %%!!  1/2/3/4  1/2/3/4    
    %{
    norm_num = 2;  %%!!  number of FPCs to use  %%!!  n_FPC / 3 / 2 / 1
    FPC_Dev_scores_twinPick_UNNM_withMedu = zeros(size(FPC_scores_twinPick_UNNM_withMedu, 1), num_ROIs);
    for ss = 1:size(FPC_scores_twinPick_UNNM_withMedu, 1)
        for rr = 1:num_ROIs
            FPC_Dev_scores_twinPick_UNNM_withMedu(ss, rr) = norm(FPC_scores_twinPick_UNNM_withMedu(ss, (rr-1)*n_FPC+1:(rr-1)*n_FPC+norm_num) - FPC_scores_twinPick_Normal_mean_ref(1, (rr-1)*n_FPC+1:(rr-1)*n_FPC+norm_num));  %%!!    %%!!  Deviation norm(distance) from Normal mean reference
        end
    end
    %}
    %}    
    subjects_twinPick_IQ10 = intersect(subjects_twinPick_All, subjects_all(~isnan(IQ10_all)));  %%!!  twinPick with IQ10  %%!!  
    Medu_twinPick_IQ10 = Medu_all(ismember(subjects_all, subjects_twinPick_IQ10));  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
    subjects_twinPick_IQ10_withMedu = subjects_twinPick_IQ10(~isnan(Medu_twinPick_IQ10));  %%!!  with IQ10 & with Medu  %%!!  
    Medu_twinPick_IQ10_withMedu = Medu_all(ismember(subjects_all, subjects_twinPick_IQ10_withMedu));  %%!!    %%!!  
    Medu_twinPick_IQ10_withMedu = Medu_twinPick_IQ10_withMedu - mean(Medu_twinPick_IQ10_withMedu);  %%!!    %%!!  centered
    NDD_twinPick_IQ10_withMedu = double(ismember(subjects_twinPick_IQ10_withMedu, subjects_twinPick_NDD));  %%!!    %%!!  categorized
    MPD_twinPick_IQ10_withMedu = double(ismember(subjects_twinPick_IQ10_withMedu, subjects_twinPick_MPD));  %%!!    %%!!  categorized
    GAAssess10_twinPick_IQ10_withMedu = cell2mat(GAAssess10_all(ismember(subjects_all, subjects_twinPick_IQ10_withMedu)));  %%!!    %%!!  
    GAAssess10_twinPick_IQ10_withMedu = GAAssess10_twinPick_IQ10_withMedu - mean(GAAssess10_twinPick_IQ10_withMedu);  %%!!    %%!!  centered
    C_twinPick_IQ10_withMedu = C(ismember(subjects_twinPick_All, subjects_twinPick_IQ10_withMedu), :);  %%!!    %%!!  categorized/centered GAB+BW+Sex for subjects_twinPick_IQ10_withMedu
    C_twinPick_IQ10_withMedu = [C_twinPick_IQ10_withMedu, Medu_twinPick_IQ10_withMedu, NDD_twinPick_IQ10_withMedu, MPD_twinPick_IQ10_withMedu, GAAssess10_twinPick_IQ10_withMedu];  %%!!    %%!!  All covs for longitudinal regression test (except for intercept 1+)
    IQ10_twinPick_IQ10_withMedu = IQ10_all(ismember(subjects_all, subjects_twinPick_IQ10_withMedu));  %%!!    %%!!  no need to center
    FPC_scores_twinPick_IQ10_withMedu = cell2mat(FPC_scores(ismember(FPC_scores(:, 2), subjects_twinPick_IQ10_withMedu), 4:end));  %%!!  
    n_FPC = size(FPC_scores_twinPick_IQ10_withMedu, 2) / num_ROIs;
    FPC_1_scores_twinPick_IQ10_withMedu = FPC_scores_twinPick_IQ10_withMedu(:, 1:n_FPC:end);  %%!!    %%!!  1/2/3/4  1/2/3/4    
    %{
    Bs_NDD = zeros(1, num_ROIs);
    Ps_NDD = zeros(1, num_ROIs);
    Bs_MPD = zeros(1, num_ROIs);
    Ps_MPD = zeros(1, num_ROIs);
    %}
    Corrs_IQ10 = zeros(1, num_ROIs);
    Ps_IQ10 = zeros(1, num_ROIs);
    PermPs_IQ10 = zeros(1, num_ROIs);  %%!!  
    alpha = 0.05;  %%!!  
    for rr = 1:num_ROIs
        %{
        y_twinPick_UNNM_withMedu = FPC_2_scores_twinPick_UNNM_withMedu(:, rr);  %%!!  1/2/3/4/Dev    
        %[B,~,R] = regress(y_twinPick_UNNM_withMedu, [ones(size(C_twinPick_UNNM_withMedu, 1), 1), C_twinPick_UNNM_withMedu]);  %%!!    %%!!  
        mdl = fitlm(C_twinPick_UNNM_withMedu, y_twinPick_UNNM_withMedu);  %%!!    %%!!  regress doesn't output individual p values; use fitlm instead, no need to include ones
        Bs_NDD(rr) = mdl.Coefficients.Estimate(6);  %%!!    %%!!  NDD
        Ps_NDD(rr) = mdl.Coefficients.pValue(6);  %%!!    %%!!  NDD
        Bs_MPD(rr) = mdl.Coefficients.Estimate(7);  %%!!    %%!!  MPD
        Ps_MPD(rr) = mdl.Coefficients.pValue(7);  %%!!    %%!!  MPD
        %}
        x_twinPick_IQ10_withMedu = FPC_1_scores_twinPick_IQ10_withMedu(:, rr);  %%!!  1/2/3/4/Dev    
        [Corr, P] = partialcorr(x_twinPick_IQ10_withMedu, IQ10_twinPick_IQ10_withMedu, C_twinPick_IQ10_withMedu);  %%!!    %%!!  , 'Type', 'Spearman'
        Corrs_IQ10(rr) = Corr;
        Ps_IQ10(rr) = P;
        % Permutation P Values (PermP)
        rand_seed = 1;  %% random seed  %%  
        perm_n = 1000;  %% number of permutations  %%  
        perm_IQ10_twinPick_IQ10_withMedus = cell(perm_n, 1);  
        rng(rand_seed, 'twister');  %%!!  
        for pp = 1:perm_n
            perm_IQ10_twinPick_IQ10_withMedus{pp} = IQ10_twinPick_IQ10_withMedu(randperm(length(IQ10_twinPick_IQ10_withMedu))); 
        end
        perm_Corrs = zeros(perm_n, 1); 
        for pp = 1:perm_n
            perm_Corrs(pp) = partialcorr(x_twinPick_IQ10_withMedu, perm_IQ10_twinPick_IQ10_withMedus{pp}, C_twinPick_IQ10_withMedu); %% 
        end
        if Corr < 0
            smaller_cnt = sum(perm_Corrs < Corr); 
        elseif Corr >= 0
            smaller_cnt = sum(perm_Corrs > Corr);
        else
            smaller_cnt = NaN; 
        end
        PermP = smaller_cnt / perm_n;  %%!!  
        PermPs_IQ10(rr) = PermP; %% 
        % scatter plots    
        x = x_twinPick_IQ10_withMedu;
        y = IQ10_twinPick_IQ10_withMedu;
        h_fig = figure(); 
        hold on;
        plt = plot(x, y, '.', 'MarkerSize', 20, 'Color', 'k');  %%  
        P = polyfit(x,y,1);
        x0 = min(x) ; x1 = max(x) ;
        xi = linspace(x0,x1) ;
        yi = P(1)*xi+P(2);
        l = plot(xi,yi,'k-') ;  %%  
        l.DisplayName = 'regression line';
        l.LineWidth = 2;
        xlabel([measure_str ' ' networks{rr} ' FPC Scores']);  %%!!  
        ylabel('IQ10');
        %title(['Sim ' sim_sstr ' - Demo ' demo_sstr]); %% 
        %xlim([ ]); %% 
        %ylim([-0.6 0.8]); %% 
        hold off;
        outfilef = [outputpath measure label '_mFPCA_twinPick_IQ10_FPC_1_scores_' num2str(rr) networks{rr} '_Scatter_' group Cov_label '.fig'];  %%!!    %%!!  IQ10    1/2/3/4/Dev    
        saveas(h_fig, outfilef);
        close(h_fig);  %  
    end
    %{
    Hs_NDD = Ps_NDD <= alpha;
    Ps_NDD_FDR = mafdr(Ps_NDD, 'BHFDR', true);
    Hs_NDD_FDR = Ps_NDD_FDR <= alpha;
    Hs_MPD = Ps_MPD <= alpha;
    Ps_MPD_FDR = mafdr(Ps_MPD, 'BHFDR', true);
    Hs_MPD_FDR = Ps_MPD_FDR <= alpha;
    outfile = [outputpath measure label '_mFPCA_twinPick_Normal_NDD_MPD_FPC_2_scores_RegressionP_' group Cov_label '.mat'];  %%!!    %%!!  Normal-NDD/-MPD    1/2/3/4/Dev    
    save(outfile, 'ROIs', 'networks', 'subjects_twinPick_UNNM_withMedu', 'FPC_scores_twinPick_UNNM_withMedu', 'FPC_2_scores_twinPick_UNNM_withMedu', 'C_twinPick_UNNM_withMedu', 'Bs_NDD', 'Ps_NDD', 'Hs_NDD', 'Ps_NDD_FDR', 'Hs_NDD_FDR', 'Bs_MPD', 'Ps_MPD', 'Hs_MPD', 'Ps_MPD_FDR', 'Hs_MPD_FDR');  %%!!    %%!!  1/2/3/4/Dev    
    %}
    Hs_IQ10 = Ps_IQ10 <= alpha;
    Ps_IQ10_FDR = mafdr(Ps_IQ10, 'BHFDR', true);
    Hs_IQ10_FDR = Ps_IQ10_FDR <= alpha;
    PermHs_IQ10 = PermPs_IQ10 <= alpha;  %%!!  
    PermPs_IQ10_FDR = mafdr(PermPs_IQ10, 'BHFDR', true);  %%!!  
    PermHs_IQ10_FDR = PermPs_IQ10_FDR <= alpha;  %%!!  
    outfile = [outputpath measure label '_mFPCA_twinPick_IQ10_FPC_1_scores_PartialCorrP_' group Cov_label '.mat'];  %%!!    %%!!  IQ10    1/2/3/4/Dev    
    save(outfile, 'ROIs', 'networks', 'subjects_twinPick_IQ10_withMedu', 'FPC_scores_twinPick_IQ10_withMedu', 'FPC_1_scores_twinPick_IQ10_withMedu', 'C_twinPick_IQ10_withMedu', 'IQ10_twinPick_IQ10_withMedu', 'Corrs_IQ10', 'Ps_IQ10', 'Hs_IQ10', 'Ps_IQ10_FDR', 'Hs_IQ10_FDR', 'PermPs_IQ10', 'PermHs_IQ10', 'PermPs_IQ10_FDR', 'PermHs_IQ10_FDR');  %%!!    %%!!  1/2/3/4/Dev    
    
    subjects_twinPick_Anxiety10 = intersect(subjects_twinPick_All, subjects_all(~isnan(Anxiety10_all)));  %%!!  twinPick with Anxiety10  %%!!  
    Medu_twinPick_Anxiety10 = Medu_all(ismember(subjects_all, subjects_twinPick_Anxiety10));  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
    subjects_twinPick_Anxiety10_withMedu = subjects_twinPick_Anxiety10(~isnan(Medu_twinPick_Anxiety10));  %%!!  with Anxiety10 & with Medu  %%!!  
    Medu_twinPick_Anxiety10_withMedu = Medu_all(ismember(subjects_all, subjects_twinPick_Anxiety10_withMedu));  %%!!    %%!!  
    Medu_twinPick_Anxiety10_withMedu = Medu_twinPick_Anxiety10_withMedu - mean(Medu_twinPick_Anxiety10_withMedu);  %%!!    %%!!  centered
    NDD_twinPick_Anxiety10_withMedu = double(ismember(subjects_twinPick_Anxiety10_withMedu, subjects_twinPick_NDD));  %%!!    %%!!  categorized
    MPD_twinPick_Anxiety10_withMedu = double(ismember(subjects_twinPick_Anxiety10_withMedu, subjects_twinPick_MPD));  %%!!    %%!!  categorized
    GAAssess10_twinPick_Anxiety10_withMedu = cell2mat(GAAssess10_all(ismember(subjects_all, subjects_twinPick_Anxiety10_withMedu)));  %%!!    %%!!  
    GAAssess10_twinPick_Anxiety10_withMedu = GAAssess10_twinPick_Anxiety10_withMedu - mean(GAAssess10_twinPick_Anxiety10_withMedu);  %%!!    %%!!  centered
    C_twinPick_Anxiety10_withMedu = C(ismember(subjects_twinPick_All, subjects_twinPick_Anxiety10_withMedu), :);  %%!!    %%!!  categorized/centered GAB+BW+Sex for subjects_twinPick_Anxiety10_withMedu
    C_twinPick_Anxiety10_withMedu = [C_twinPick_Anxiety10_withMedu, Medu_twinPick_Anxiety10_withMedu, NDD_twinPick_Anxiety10_withMedu, MPD_twinPick_Anxiety10_withMedu, GAAssess10_twinPick_Anxiety10_withMedu];  %%!!    %%!!  All covs for longitudinal regression test (except for intercept 1+)
    Anxiety10_twinPick_Anxiety10_withMedu = Anxiety10_all(ismember(subjects_all, subjects_twinPick_Anxiety10_withMedu));  %%!!    %%!!  no need to center
    FPC_scores_twinPick_Anxiety10_withMedu = cell2mat(FPC_scores(ismember(FPC_scores(:, 2), subjects_twinPick_Anxiety10_withMedu), 4:end));  %%!!  
    n_FPC = size(FPC_scores_twinPick_Anxiety10_withMedu, 2) / num_ROIs;
    FPC_1_scores_twinPick_Anxiety10_withMedu = FPC_scores_twinPick_Anxiety10_withMedu(:, 1:n_FPC:end);  %%!!    %%!!  1/2/3/4  1/2/3/4    
    Corrs_Anxiety10 = zeros(1, num_ROIs);
    Ps_Anxiety10 = zeros(1, num_ROIs);
    PermPs_Anxiety10 = zeros(1, num_ROIs);  %%!!  
    alpha = 0.05;  %%!!  
    for rr = 1:num_ROIs
        x_twinPick_Anxiety10_withMedu = FPC_1_scores_twinPick_Anxiety10_withMedu(:, rr);  %%!!  1/2/3/4/Dev    
        [Corr, P] = partialcorr(x_twinPick_Anxiety10_withMedu, Anxiety10_twinPick_Anxiety10_withMedu, C_twinPick_Anxiety10_withMedu);  %%!!    %%!!  , 'Type', 'Spearman'
        Corrs_Anxiety10(rr) = Corr;
        Ps_Anxiety10(rr) = P;
        % Permutation P Values (PermP)
        rand_seed = 1;  %% random seed  %%  
        perm_n = 1000;  %% number of permutations  %%  
        perm_Anxiety10_twinPick_Anxiety10_withMedus = cell(perm_n, 1);  
        rng(rand_seed, 'twister');  %%!!  
        for pp = 1:perm_n
            perm_Anxiety10_twinPick_Anxiety10_withMedus{pp} = Anxiety10_twinPick_Anxiety10_withMedu(randperm(length(Anxiety10_twinPick_Anxiety10_withMedu))); 
        end
        perm_Corrs = zeros(perm_n, 1); 
        for pp = 1:perm_n
            perm_Corrs(pp) = partialcorr(x_twinPick_Anxiety10_withMedu, perm_Anxiety10_twinPick_Anxiety10_withMedus{pp}, C_twinPick_Anxiety10_withMedu); %% 
        end
        if Corr < 0
            smaller_cnt = sum(perm_Corrs < Corr); 
        elseif Corr >= 0
            smaller_cnt = sum(perm_Corrs > Corr);
        else
            smaller_cnt = NaN; 
        end
        PermP = smaller_cnt / perm_n;  %%!!  
        PermPs_Anxiety10(rr) = PermP; %% 
        % scatter plots    
        x = x_twinPick_Anxiety10_withMedu;
        y = Anxiety10_twinPick_Anxiety10_withMedu;
        h_fig = figure(); 
        hold on;
        plt = plot(x, y, '.', 'MarkerSize', 20, 'Color', 'k');  %%  
        P = polyfit(x,y,1);
        x0 = min(x) ; x1 = max(x) ;
        xi = linspace(x0,x1) ;
        yi = P(1)*xi+P(2);
        l = plot(xi,yi,'k-') ;  %%  
        l.DisplayName = 'regression line';
        l.LineWidth = 2;
        xlabel([measure_str ' ' networks{rr} ' FPC Scores']);  %%!!  
        ylabel('Anxiety10');
        %title(['Sim ' sim_sstr ' - Demo ' demo_sstr]); %% 
        %xlim([ ]); %% 
        %ylim([-0.6 0.8]); %% 
        hold off;
        outfilef = [outputpath measure label '_mFPCA_twinPick_Anxiety10_FPC_1_scores_' num2str(rr) networks{rr} '_Scatter_' group Cov_label '.fig'];  %%!!    %%!!  Anxiety10    1/2/3/4/Dev    
        saveas(h_fig, outfilef);
        close(h_fig);  %  
    end
    Hs_Anxiety10 = Ps_Anxiety10 <= alpha;
    Ps_Anxiety10_FDR = mafdr(Ps_Anxiety10, 'BHFDR', true);
    Hs_Anxiety10_FDR = Ps_Anxiety10_FDR <= alpha;
    PermHs_Anxiety10 = PermPs_Anxiety10 <= alpha;  %%!!  
    PermPs_Anxiety10_FDR = mafdr(PermPs_Anxiety10, 'BHFDR', true);  %%!!  
    PermHs_Anxiety10_FDR = PermPs_Anxiety10_FDR <= alpha;  %%!!  
    outfile = [outputpath measure label '_mFPCA_twinPick_Anxiety10_FPC_1_scores_PartialCorrP_' group Cov_label '.mat'];  %%!!    %%!!  Anxiety10    1/2/3/4/Dev    
    save(outfile, 'ROIs', 'networks', 'subjects_twinPick_Anxiety10_withMedu', 'FPC_scores_twinPick_Anxiety10_withMedu', 'FPC_1_scores_twinPick_Anxiety10_withMedu', 'C_twinPick_Anxiety10_withMedu', 'Anxiety10_twinPick_Anxiety10_withMedu', 'Corrs_Anxiety10', 'Ps_Anxiety10', 'Hs_Anxiety10', 'Ps_Anxiety10_FDR', 'Hs_Anxiety10_FDR', 'PermPs_Anxiety10', 'PermHs_Anxiety10', 'PermPs_Anxiety10_FDR', 'PermHs_Anxiety10_FDR');  %%!!    %%!!  1/2/3/4/Dev    

    subjects_twinPick_Depression10 = intersect(subjects_twinPick_All, subjects_all(~isnan(Depression10_all)));  %%!!  twinPick with Depression10  %%!!  
    Medu_twinPick_Depression10 = Medu_all(ismember(subjects_all, subjects_twinPick_Depression10));  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
    subjects_twinPick_Depression10_withMedu = subjects_twinPick_Depression10(~isnan(Medu_twinPick_Depression10));  %%!!  with Depression10 & with Medu  %%!!  
    Medu_twinPick_Depression10_withMedu = Medu_all(ismember(subjects_all, subjects_twinPick_Depression10_withMedu));  %%!!    %%!!  
    Medu_twinPick_Depression10_withMedu = Medu_twinPick_Depression10_withMedu - mean(Medu_twinPick_Depression10_withMedu);  %%!!    %%!!  centered
    NDD_twinPick_Depression10_withMedu = double(ismember(subjects_twinPick_Depression10_withMedu, subjects_twinPick_NDD));  %%!!    %%!!  categorized
    MPD_twinPick_Depression10_withMedu = double(ismember(subjects_twinPick_Depression10_withMedu, subjects_twinPick_MPD));  %%!!    %%!!  categorized
    GAAssess10_twinPick_Depression10_withMedu = cell2mat(GAAssess10_all(ismember(subjects_all, subjects_twinPick_Depression10_withMedu)));  %%!!    %%!!  
    GAAssess10_twinPick_Depression10_withMedu = GAAssess10_twinPick_Depression10_withMedu - mean(GAAssess10_twinPick_Depression10_withMedu);  %%!!    %%!!  centered
    C_twinPick_Depression10_withMedu = C(ismember(subjects_twinPick_All, subjects_twinPick_Depression10_withMedu), :);  %%!!    %%!!  categorized/centered GAB+BW+Sex for subjects_twinPick_Depression10_withMedu
    C_twinPick_Depression10_withMedu = [C_twinPick_Depression10_withMedu, Medu_twinPick_Depression10_withMedu, NDD_twinPick_Depression10_withMedu, MPD_twinPick_Depression10_withMedu, GAAssess10_twinPick_Depression10_withMedu];  %%!!    %%!!  All covs for longitudinal regression test (except for intercept 1+)
    Depression10_twinPick_Depression10_withMedu = Depression10_all(ismember(subjects_all, subjects_twinPick_Depression10_withMedu));  %%!!    %%!!  no need to center
    FPC_scores_twinPick_Depression10_withMedu = cell2mat(FPC_scores(ismember(FPC_scores(:, 2), subjects_twinPick_Depression10_withMedu), 4:end));  %%!!  
    n_FPC = size(FPC_scores_twinPick_Depression10_withMedu, 2) / num_ROIs;
    FPC_1_scores_twinPick_Depression10_withMedu = FPC_scores_twinPick_Depression10_withMedu(:, 1:n_FPC:end);  %%!!    %%!!  1/2/3/4  1/2/3/4    
    Corrs_Depression10 = zeros(1, num_ROIs);
    Ps_Depression10 = zeros(1, num_ROIs);
    PermPs_Depression10 = zeros(1, num_ROIs);  %%!!  
    alpha = 0.05;  %%!!  
    for rr = 1:num_ROIs
        x_twinPick_Depression10_withMedu = FPC_1_scores_twinPick_Depression10_withMedu(:, rr);  %%!!  1/2/3/4/Dev    
        [Corr, P] = partialcorr(x_twinPick_Depression10_withMedu, Depression10_twinPick_Depression10_withMedu, C_twinPick_Depression10_withMedu);  %%!!    %%!!  , 'Type', 'Spearman'
        Corrs_Depression10(rr) = Corr;
        Ps_Depression10(rr) = P;
        % Permutation P Values (PermP)
        rand_seed = 1;  %% random seed  %%  
        perm_n = 1000;  %% number of permutations  %%  
        perm_Depression10_twinPick_Depression10_withMedus = cell(perm_n, 1);  
        rng(rand_seed, 'twister');  %%!!  
        for pp = 1:perm_n
            perm_Depression10_twinPick_Depression10_withMedus{pp} = Depression10_twinPick_Depression10_withMedu(randperm(length(Depression10_twinPick_Depression10_withMedu))); 
        end
        perm_Corrs = zeros(perm_n, 1); 
        for pp = 1:perm_n
            perm_Corrs(pp) = partialcorr(x_twinPick_Depression10_withMedu, perm_Depression10_twinPick_Depression10_withMedus{pp}, C_twinPick_Depression10_withMedu); %% 
        end
        if Corr < 0
            smaller_cnt = sum(perm_Corrs < Corr); 
        elseif Corr >= 0
            smaller_cnt = sum(perm_Corrs > Corr);
        else
            smaller_cnt = NaN; 
        end
        PermP = smaller_cnt / perm_n;  %%!!  
        PermPs_Depression10(rr) = PermP; %% 
        % scatter plots    
        x = x_twinPick_Depression10_withMedu;
        y = Depression10_twinPick_Depression10_withMedu;
        h_fig = figure(); 
        hold on;
        plt = plot(x, y, '.', 'MarkerSize', 20, 'Color', 'k');  %%  
        P = polyfit(x,y,1);
        x0 = min(x) ; x1 = max(x) ;
        xi = linspace(x0,x1) ;
        yi = P(1)*xi+P(2);
        l = plot(xi,yi,'k-') ;  %%  
        l.DisplayName = 'regression line';
        l.LineWidth = 2;
        xlabel([measure_str ' ' networks{rr} ' FPC Scores']);  %%!!  
        ylabel('Depression10');
        %title(['Sim ' sim_sstr ' - Demo ' demo_sstr]); %% 
        %xlim([ ]); %% 
        %ylim([-0.6 0.8]); %% 
        hold off;
        outfilef = [outputpath measure label '_mFPCA_twinPick_Depression10_FPC_1_scores_' num2str(rr) networks{rr} '_Scatter_' group Cov_label '.fig'];  %%!!    %%!!  Depression10    1/2/3/4/Dev    
        saveas(h_fig, outfilef);
        close(h_fig);  %  
    end
    Hs_Depression10 = Ps_Depression10 <= alpha;
    Ps_Depression10_FDR = mafdr(Ps_Depression10, 'BHFDR', true);
    Hs_Depression10_FDR = Ps_Depression10_FDR <= alpha;
    PermHs_Depression10 = PermPs_Depression10 <= alpha;  %%!!  
    PermPs_Depression10_FDR = mafdr(PermPs_Depression10, 'BHFDR', true);  %%!!  
    PermHs_Depression10_FDR = PermPs_Depression10_FDR <= alpha;  %%!!  
    outfile = [outputpath measure label '_mFPCA_twinPick_Depression10_FPC_1_scores_PartialCorrP_' group Cov_label '.mat'];  %%!!    %%!!  Depression10    1/2/3/4/Dev    
    save(outfile, 'ROIs', 'networks', 'subjects_twinPick_Depression10_withMedu', 'FPC_scores_twinPick_Depression10_withMedu', 'FPC_1_scores_twinPick_Depression10_withMedu', 'C_twinPick_Depression10_withMedu', 'Depression10_twinPick_Depression10_withMedu', 'Corrs_Depression10', 'Ps_Depression10', 'Hs_Depression10', 'Ps_Depression10_FDR', 'Hs_Depression10_FDR', 'PermPs_Depression10', 'PermHs_Depression10', 'PermPs_Depression10_FDR', 'PermHs_Depression10_FDR');  %%!!    %%!!  1/2/3/4/Dev    
    
end

end


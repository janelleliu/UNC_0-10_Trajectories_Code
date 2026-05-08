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
measures_str = {'Str', 'Enodal', 'Elocal', 'McosSim', 'Gradient1', 'Gradient2'};  %%!!    %%!!    %%!!  , 'Dispersion', 'Dispersion-Normalized'
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

for mm=1:length(measures)  %%!!    %%!!  
    measure = measures{mm};
    measure_str = measures_str{mm};  %%!!    %%!!  

if ismember(measure, {'Str', 'BC', 'Enodal', 'Elocal',  'Str1', 'BC1', 'Enodal1', 'Elocal1'})  %%!!  %%!!  graph measures
    label = graph_label;  %%!!  
else
    label = '';  %%!!  
end

datapath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/barplots_results/' measure label Cov_label '/'];  %%!!    %%!!  
outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/barplots_results_Predictions_GAB_controlNDD/' measure label Cov_label '/'];  %%!!    %%!!  
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
%     subjects_twinPick_Normal_32W = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_32W_Healthy.txt']);  %%!!    %%!!  Normal 32W  
%     subjects_twinPick_Preterm_32W = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_Preterm_32W.txt']);  %%!!    %%!!  Preterm 32W  
    subjects_twinPick_NDD = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_ADAU.txt']);  %%!!    %%!!  NDD  
    subjects_twinPick_MPD = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_MaternalPD.txt']);  %%!!    %%!!  MPD  
    %subjects_twinPick_UNNM = union(subjects_twinPick_Normal, subjects_twinPick_NDD);
    %subjects_twinPick_UNNM = union(subjects_twinPick_UNNM, subjects_twinPick_MPD);  %%!!  Union of Normal/NDD/MPD
%     subjects_twinPick_UNP_32W = union(subjects_twinPick_Normal_32W, subjects_twinPick_Preterm_32W);  %%!!  Union of Normal/Preterm 32W
    Medu_twinPick_All = Medu_all(ismember(subjects_all, subjects_twinPick_All));  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
    subjects_twinPick_All_withMedu = subjects_twinPick_All(~isnan(Medu_twinPick_All));  %%!!  Union of Normal/Preterm 32W & with Medu  %%!!  
    Medu_twinPick_All_withMedu = Medu_all(ismember(subjects_all, subjects_twinPick_All_withMedu));  %%!!    %%!!  
    Medu_twinPick_All_withMedu = Medu_twinPick_All_withMedu - mean(Medu_twinPick_All_withMedu);  %%!!    %%!!  centered
    NDD_twinPick_All_withMedu = double(ismember(subjects_twinPick_All_withMedu, subjects_twinPick_NDD));  %%!!    %%!!  categorized
    MPD_twinPick_All_withMedu = double(ismember(subjects_twinPick_All_withMedu, subjects_twinPick_MPD));  %%!!    %%!!  categorized
    cov_file = [covpath 'M_FC_Z_Covs_twinPick_All_0.3mm_notr90_UNC_' group '.mat'];
    load(cov_file);  %%!!  C as categorized/centered GAB+GAS+BW+Sex +Scanner+MeanFD+ScanLength
    % Preterm_32W_twinPick_All_withMedu = double(ismember(subjects_twinPick_All_withMedu, subjects_twinPick_Preterm_32W));  %%!!    %%!!  categorized
    C = C(:, [2,4]);  %%!!  C as categorized/centered GAS+Sex for subjects_twinPick_All  %%!!  %%!!  
    C_twinPick_All_withMedu = C(ismember(subjects_twinPick_All, subjects_twinPick_All_withMedu), :);  %%!!    %%!!  categorized/centered Sex for subjects_twinPick_All_withMedu
    C_twinPick_All_withMedu = [C_twinPick_All_withMedu, Medu_twinPick_All_withMedu, NDD_twinPick_All_withMedu, MPD_twinPick_All_withMedu];  %%!!    %%!!  All covs for longitudinal regression test (except for intercept 1+)
    GAB = C_raw(:, 1);  %%!!  original GAB
    GAB_twinPick_All_withMedu = GAB(ismember(subjects_twinPick_All, subjects_twinPick_All_withMedu));  %%!!    %%!!  original GAB for subjects_twinPick_All_withMedu
    infile = [datapath measure label '_Mean_twinPick_Heatmap_' group Cov_label '.mat'];  %%!!  All
    load(infile);
    measures_network_twinPick_All_withMedu = measures_network(ismember(subjects_twinPick_All, subjects_twinPick_All_withMedu), :);  %%!!  
    Corrs_GAB = zeros(1, num_ROIs);
    Ps_GAB = zeros(1, num_ROIs);
    PermPs_GAB = zeros(1, num_ROIs);  %%!!  
    alpha = 0.05;  %%!!  
    for rr = 1:num_ROIs
        y_twinPick_All_withMedu = measures_network_twinPick_All_withMedu(:, rr);  %%!!  
        [Corr, P] = partialcorr(GAB_twinPick_All_withMedu, y_twinPick_All_withMedu, C_twinPick_All_withMedu);  %%!!    %%!!  , 'Type', 'Spearman'
        Corrs_GAB(rr) = Corr;
        Ps_GAB(rr) = P;
        % Permutation P Values (PermP)
        rand_seed = 1;  %% random seed  %%  
        perm_n = 1000;  %% number of permutations  %%  
        perm_GAB_twinPick_All_withMedus = cell(perm_n, 1);  
        rng(rand_seed, 'twister');  %%!!  
        for pp = 1:perm_n
            perm_GAB_twinPick_All_withMedus{pp} = GAB_twinPick_All_withMedu(randperm(length(GAB_twinPick_All_withMedu))); 
        end
        perm_Corrs = zeros(perm_n, 1); 
        for pp = 1:perm_n
            perm_Corrs(pp) = partialcorr(perm_GAB_twinPick_All_withMedus{pp}, y_twinPick_All_withMedu, C_twinPick_All_withMedu); %% 
        end
        %{
        if Corr < 0
            smaller_cnt = sum(perm_Corrs < Corr); 
        elseif Corr >= 0
            smaller_cnt = sum(perm_Corrs > Corr);
        else
            smaller_cnt = NaN; 
        end
        %}
        smaller_cnt = sum(abs(perm_Corrs) >= abs(Corr));  %%!!  Two-tailed Test
        PermP = (smaller_cnt+1) / (perm_n+1);  %%!!  to avoid 0
        PermPs_GAB(rr) = PermP; %% 
        % scatter plots    
        x = GAB_twinPick_All_withMedu;
        y = y_twinPick_All_withMedu;
        h_fig = figure(); 
        hold on;
        plt = plot(x, y, '.', 'MarkerSize', 15, 'Color', [0.3, 0.5, 0.8]);  %%  Updated
        P = polyfit(x,y,1);
        x0 = min(x) ; x1 = max(x) ;
        xi = linspace(x0,x1) ;
        yi = P(1)*xi+P(2);
        l = plot(xi,yi,'k-') ;  %%  
        l.DisplayName = 'regression line';
        l.LineWidth = 2;
        xlabel('Gestational Age at Birth');
        ylabel([measure_str ' ' networks{rr} ' ' group]);  %%!!    %%!!  
        %title(['Sim ' sim_sstr ' - Demo ' demo_sstr]); %% 
        %xlim([ ]); %% 
        %ylim([-0.6 0.8]); %% 
        set(gca, 'FontSize', 15, 'FontWeight', 'bold');  %%!!  Updated
        annotation('textbox', [0.70, 0.84, 0.1, 0.1], 'String', ['Corr: ' sprintf('%.3f', Corr)], 'EdgeColor', 'none', 'FontSize', 15, 'FontWeight', 'bold');  %%!!  Updated
        if PermP >= 0.001
            PermP_str = sprintf('%.3f', PermP);
            PermP_str = PermP_str(2:end);
        else
            PermP_str = '<.001';
        end
        annotation('textbox', [0.68, 0.80, 0.1, 0.1], 'String', ['PermP: ' PermP_str], 'EdgeColor', 'none', 'FontSize', 15, 'FontWeight', 'bold');  %%!!  Updated
        hold off;
        outfilef = [outputpath measure label '_Mean_twinPick_GAB_Network_' num2str(rr) networks{rr} '_Scatter_' group Cov_label '.png'];  %%!!    %%!!  GAB    
        saveas(h_fig, outfilef);
        close(h_fig);  %  
    end
    Hs_GAB = Ps_GAB <= alpha;
    Ps_GAB_FDR = mafdr(Ps_GAB, 'BHFDR', true);
    Hs_GAB_FDR = Ps_GAB_FDR <= alpha;
    PermHs_GAB = PermPs_GAB <= alpha;  %%!!  
    PermPs_GAB_FDR = mafdr(PermPs_GAB, 'BHFDR', true);  %%!!  
    PermHs_GAB_FDR = PermPs_GAB_FDR <= alpha;  %%!!  
    outfile = [outputpath measure label '_Mean_twinPick_GAB_Network_PartialCorrP_' group Cov_label '.mat'];  %%!!    %%!!  GAB    
    save(outfile, 'ROIs', 'networks', 'subjects_twinPick_All_withMedu', 'measures_network_twinPick_All_withMedu', 'C_twinPick_All_withMedu', 'GAB_twinPick_All_withMedu', 'Corrs_GAB', 'Ps_GAB', 'Hs_GAB', 'Ps_GAB_FDR', 'Hs_GAB_FDR', 'PermPs_GAB', 'PermHs_GAB', 'PermPs_GAB_FDR', 'PermHs_GAB_FDR');  %%!!    %%!!  
    
end

end


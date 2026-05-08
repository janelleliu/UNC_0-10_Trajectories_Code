clear
clc

mask_inds_file = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-4mm-mask-inds.nii.gz'; %%    %%!!  %%!!  MUST USE MASK!!!!    
nii_mask_inds = load_nii(mask_inds_file);
W_mask_inds = nii_mask_inds.img;

maskfile = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-funPar-4mm-mask-inds.nii.gz']; % 2yr funPar 278 ROIs  %%!!  %%!!  
nii_mask = load_nii(maskfile);
W_mask = nii_mask.img;

level = 'ROIs';  %%!!  %%!!  2yr funPar 278 ROIs
load('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/names_aal.mat');  %%!!  
funPar_aal_inds = load('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/2yr-index-conversion_c.txt');  %%!!  
names_funPar = names_90ROIs(funPar_aal_inds);  %%!!  %%!!  
num_ROIs = length(names_funPar);  %%!!  2yr funPar 278 ROIs
ROIs = names_funPar';  %%!!  %%!!  

%Colors = [120 18 134; 70 130 180; 0 118 14; 196 58 250; 220 248 164; 230 148 34; 205 62 78; 128 128 128] / 255;  %%!!  RGB values for Yeo 8 networks  

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

for mm=5:6%1:length(measures)  %%!!    %%!!  
    measure = measures{mm};
    measure_str = measures_str{mm};  %%!!    %%!!  

if ismember(measure, {'Str', 'BC', 'Enodal', 'Elocal',  'Str1', 'BC1', 'Enodal1', 'Elocal1'})  %%!!  %%!!  graph measures
    label = graph_label;  %%!!  
else
    label = '';  %%!!  
end

datapath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/barplots_results_' level '/' measure label Cov_label '/'];  %%!!    %%!!  
outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/barplots_results_GroupComp_' level '/' measure label Cov_label '/'];  %%!!    %%!!  
if ~exist(outputpath, 'dir')
    mkdir(outputpath);
end

for gg = 1:length(groups)
    group = groups{gg};
    group_s = groups_s{gg};
    subjects_twinPick_All = importSubjIDs(['/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists_0.3mm/' group_s '_full_subject_updated_final_twinPick.txt']);  %%!!    %%!!  All  
    subjects_twinPick_Normal = importSubjIDs(['/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists_0.3mm/' group_s '_full_subject_updated_final_twinPick_32W_Healthy.txt']);  %%!!    %%!!  Normal  
    subjects_twinPick_NDD = importSubjIDs(['/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists_0.3mm/' group_s '_full_subject_updated_final_twinPick_ADAU.txt']);  %%!!    %%!!  NDD  
    subjects_twinPick_MPD = importSubjIDs(['/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists_0.3mm/' group_s '_full_subject_updated_final_twinPick_MaternalPD.txt']);  %%!!    %%!!  MPD  
    inds_Normal = ismember(subjects_twinPick_All, subjects_twinPick_Normal);  %%!!  
    inds_NDD = ismember(subjects_twinPick_All, subjects_twinPick_NDD);  %%!!  
    inds_MPD = ismember(subjects_twinPick_All, subjects_twinPick_MPD);  %%!!  
    
    infile = [datapath measure label '_Mean_twinPick_Heatmap_' group Cov_label '.mat'];  %%!!  All
    load(infile);
    measures_ROI_Normal = measures_ROI(inds_Normal, :);  %%!!  
    measures_ROI_NDD = measures_ROI(inds_NDD, :);  %%!!  
    measures_ROI_MPD = measures_ROI(inds_MPD, :);  %%!!  
    
    measures_ROI_Normal_mean = mean(measures_ROI_Normal, 1);
    measures_ROI_Normal_sem = std(measures_ROI_Normal, 1) / sqrt(size(measures_ROI_Normal, 1));
    measures_ROI_NDD_mean = mean(measures_ROI_NDD, 1);
    measures_ROI_NDD_sem = std(measures_ROI_NDD, 1) / sqrt(size(measures_ROI_NDD, 1));
    measures_ROI_MPD_mean = mean(measures_ROI_MPD, 1);
    measures_ROI_MPD_sem = std(measures_ROI_MPD, 1) / sqrt(size(measures_ROI_MPD, 1));
    [~, rank_inds] = sort(measures_ROI_Normal_mean, 'descend');  %%!!  ranked by Normal mean
    ROIs_ranked = ROIs(rank_inds);
    measures_ROI_Normal_mean_ranked = measures_ROI_Normal_mean(rank_inds);
    measures_ROI_Normal_sem_ranked = measures_ROI_Normal_sem(rank_inds);
    measures_ROI_NDD_mean_ranked = measures_ROI_NDD_mean(rank_inds);
    measures_ROI_NDD_sem_ranked = measures_ROI_NDD_sem(rank_inds);
    measures_ROI_MPD_mean_ranked = measures_ROI_MPD_mean(rank_inds);
    measures_ROI_MPD_sem_ranked = measures_ROI_MPD_sem(rank_inds);
    
    x = 1:num_ROIs;  %%!!  
    y = [measures_ROI_Normal_mean_ranked; measures_ROI_NDD_mean_ranked];  %%!!  Normal-NDD
    err = [measures_ROI_Normal_sem_ranked; measures_ROI_NDD_sem_ranked];  %%!!  Normal-NDD
    figure;  %%!!  
    hold on
    b = bar(x, y, 'grouped', 'FaceColor', 'flat', 'LineWidth', 1);  %%!!  
    b(1).LineStyle = '-';  %%!! 
    b(2).LineStyle = '--';  %%!! 
%     for i=1:length(x)
%         b(1).CData(i,:) = Colors(rank_inds(i),:);  %%!!  
%         b(2).CData(i,:) = Colors(rank_inds(i),:);  %%!!  
%     end
    [ngroups, nbars] = size(y);
    x_err = nan(ngroups, nbars);
    for i = 1:ngroups
        x_err(i, :) = b(i).XEndPoints;
    end
    errorbar(x_err, y, err, 'k', 'linestyle', 'none', 'LineWidth', 1.5);  %%!!    %%!!  
    %{
    numGroups = size(y, 1);
    numVars = size(y, 2);
    groupWidth = min(0.8, numGroups/(numGroups + 1.5));
    for i = 1:numGroups
        % X positions for bars in this group
        x_err = (1:numVars) - groupWidth/2 + (2*i-1) * groupWidth / (2*numGroups);
        errorbar(x_err, y(i,:), err(i,:), 'k', 'linestyle', 'none');  %%!!  also works, the same    
    end
    %}
    %errorbar(x, y, err, '.k');  %%!!  
    xticks(1:num_ROIs);  %%!!  
    xticklabels(ROIs_ranked);  %%!!  
    ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['Mean ' measure_str ' Normal-NDD']);  %%!!    %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 13);  %%!!  
    hold off
    outfile1 = [outputpath measure label '_Mean_twinPick_Normal_NDD_Heatmap_Ranked_Bar_' group Cov_label '.fig'];  %%!!    %%!!  Normal-NDD    
    saveas(gcf, outfile1);  %%!!  
    outfile2 = [outputpath measure label '_Mean_twinPick_Normal_NDD_Heatmap_Ranked_Bar_' group Cov_label '.png'];  %%!!    %%!!  Normal-NDD    
    saveas(gcf, outfile2);  %%!!  
    close; %% 
    
    x = 1:num_ROIs;  %%!!  
    y = [measures_ROI_Normal_mean_ranked; measures_ROI_MPD_mean_ranked];  %%!!  Normal-MPD
    err = [measures_ROI_Normal_sem_ranked; measures_ROI_MPD_sem_ranked];  %%!!  Normal-MPD
    figure;  %%!!  
    hold on
    b = bar(x, y, 'grouped', 'FaceColor', 'flat', 'LineWidth', 1);  %%!!  
    b(1).LineStyle = '-';  %%!! 
    b(2).LineStyle = '--';  %%!! 
%     for i=1:length(x)
%         b(1).CData(i,:) = Colors(rank_inds(i),:);  %%!!  
%         b(2).CData(i,:) = Colors(rank_inds(i),:);  %%!!  
%     end
    [ngroups, nbars] = size(y);
    x_err = nan(ngroups, nbars);
    for i = 1:ngroups
        x_err(i, :) = b(i).XEndPoints;
    end
    errorbar(x_err, y, err, 'k', 'linestyle', 'none', 'LineWidth', 1.5);  %%!!    %%!!  
    %{
    numGroups = size(y, 1);
    numVars = size(y, 2);
    groupWidth = min(0.8, numGroups/(numGroups + 1.5));
    for i = 1:numGroups
        % X positions for bars in this group
        x_err = (1:numVars) - groupWidth/2 + (2*i-1) * groupWidth / (2*numGroups);
        errorbar(x_err, y(i,:), err(i,:), 'k', 'linestyle', 'none');  %%!!  also works, the same    
    end
    %}
    %errorbar(x, y, err, '.k');  %%!!  
    xticks(1:num_ROIs);  %%!!  
    xticklabels(ROIs_ranked);  %%!!  
    ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['Mean ' measure_str ' Normal-MPD']);  %%!!    %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 13);  %%!!  
    hold off
    outfile1 = [outputpath measure label '_Mean_twinPick_Normal_MPD_Heatmap_Ranked_Bar_' group Cov_label '.fig'];  %%!!    %%!!  Normal-MPD    
    saveas(gcf, outfile1);  %%!!  
    outfile2 = [outputpath measure label '_Mean_twinPick_Normal_MPD_Heatmap_Ranked_Bar_' group Cov_label '.png'];  %%!!    %%!!  Normal-MPD    
    saveas(gcf, outfile2);  %%!!  
    close; %% 
    
end

end


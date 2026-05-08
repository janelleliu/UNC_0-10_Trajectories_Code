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
measures = {'Str', 'Enodal', 'Elocal', 'McosSim2', 'Gradient1_AlignedToHCP', 'Gradient2_AlignedToHCP'};  %%!!    %%!!    %%!!  
Cov_label = '';  %%!!    %%!!  ''(original) / '_Harmo'  %%!!    %%!!  _Harmo
if strcmp(Cov_label, '')
    ylims = [0,200; 0.15,0.35; 0.2,0.45; 0.15,0.6; -3,3; -3,3];  %%!!    %%!!    %%!!  
    groups = {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear', 'HCP'};  %%!!  
    groups_s = {'0', '1', '2', '4', '6', '8', '10', 'HCP'};  %%!!  
elseif strcmp(Cov_label, '_Harmo')
    ylims = [50,200; 0.25,0.35; 0.3,0.5; 0.15,0.6; -3,3; -3,3];  %%!!    %%!!    %%!!  
    groups = {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear', 'HCP'};  %%!!  
    groups_s = {'0', '1', '2', '4', '6', '8', '10', 'HCP'};  %%!!  
end

for mm=1:length(measures)  %%!!    %%!!  5:6%
    measure = measures{mm};

if ismember(measure, {'Str', 'BC', 'Enodal', 'Elocal',  'Str1', 'BC1', 'Enodal1', 'Elocal1'})  %%!!  %%!!  graph measures
    label = graph_label;  %%!!  
else
    label = '';  %%!!  
end

datapath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/' measure label Cov_label '/'];  %%!!  Original/Harmo Heatmaps  %%!!  
outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/barplots_results/' measure label Cov_label '/'];  %%!!  %%!!  
if ~exist(outputpath, 'dir')
    mkdir(outputpath);
end

for gg = 1:length(groups)
    group = groups{gg};
    group_s = groups_s{gg};
    datadir = [datapath group '/'];
    if strcmp(group, 'HCP')
        subjects = importSubjIDs(['/media/zhark2/glab3/HCP/lists/' group_s '_list_gsr_notr1500_CB.txt']);  %%!!  
    else
        subjects = importSubjIDs(['/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists_0.3mm/' group_s '_full_subject_updated_final_twinPick.txt']);  %%!!    %%!!  All  
    end
    num_subj = length(subjects);
    measures_network = zeros(num_subj, num_ROIs);  %%!!  
    for ss = 1:num_subj
        subj = subjects{ss};
        infile = [datadir subj '_' measure '_Heatmap_' group Cov_label '.nii.gz'];  %%!!    %%!!  
        nii = load_nii(infile);
        W = nii.img;
        for rr = 1:num_ROIs
            ROI = ROIs{rr};
            network = networks{rr};  %%!!  only used for visualization  
            measure_network = mean(W(W_mask==rr & W_mask_inds~=0));  %%!!  %%!!  MUST USE MASK!!!!    %%!!  %%!!  
            measures_network(ss, rr) = measure_network;
        end
    end
    measures_network_mean = mean(measures_network, 1);
    measures_network_sem = std(measures_network, 1) / sqrt(size(measures_network, 1));
    [~, rank_inds] = sort(measures_network_mean, 'descend');  %%!!  
    measures_network_mean_ranked = measures_network_mean(rank_inds);
    measures_network_sem_ranked = measures_network_sem(rank_inds);
    networks_ranked = networks(rank_inds);
    if strcmp(group, 'HCP')
        outfile0 = [outputpath measure label '_Mean_Heatmap_' group Cov_label '.mat'];  %%!!    %%!!  
    else
        outfile0 = [outputpath measure label '_Mean_twinPick_Heatmap_' group Cov_label '.mat'];  %%!!  _32W_Healthy  %%!!  
    end
    save(outfile0, 'group', 'group_s', 'ROIs', 'networks', 'Colors', 'measures_network', 'measures_network_mean', 'measures_network_sem', 'rank_inds', 'measures_network_mean_ranked', 'measures_network_sem_ranked', 'networks_ranked');
    x = 1:num_ROIs;  %%!!  
    y = measures_network_mean_ranked;  %%!!  
    err = measures_network_sem_ranked;  %%!!  
    figure;  %%!!  
    hold on
    b = bar(x, y, 'FaceColor', 'flat');  %%!!  
    for i=1:length(x)
        b.CData(i,:) = Colors(rank_inds(i),:);  %%!!  
    end
    errorbar(x, y, err, '.k');  %%!!  
    xticks(1:num_ROIs);  %%!!  
    xticklabels(networks_ranked);  %%!!  
    ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['Mean ' measure]);  %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 15);  %%!!  
    hold off
    if strcmp(group, 'HCP')
        outfile1 = [outputpath measure label '_Mean_Heatmap_Ranked_Bar_' group Cov_label '.fig'];  %%!!    %%!!  
    else
        outfile1 = [outputpath measure label '_Mean_twinPick_Heatmap_Ranked_Bar_' group Cov_label '.fig'];  %%!!  _32W_Healthy  %%!!  
    end
    saveas(gcf, outfile1);  %%!!  
    if strcmp(group, 'HCP')
        outfile2 = [outputpath measure label '_Mean_Heatmap_Ranked_Bar_' group Cov_label '.png'];  %%!!    %%!!  
    else
        outfile2 = [outputpath measure label '_Mean_twinPick_Heatmap_Ranked_Bar_' group Cov_label '.png'];  %%!!  _32W_Healthy  %%!!  
    end
    saveas(gcf, outfile2);  %%!!  
    close; %% 
    
    %{
    if strcmp(label, '_funPar')  %%!!    %%!!  
        aal_ind_funPar = load('2yr-index-conversion_c.txt');
        load('names_aal.mat');
        names_funPar = names_90ROIs(aal_ind_funPar);
        if strcmp(group, 'HCP')
            measures_funPar = load([datapath measure label '_Mean_Heatmap_' group '.1D']);
        else
            measures_funPar = load([datapath measure label '_Mean_twinPick_Heatmap_' group '.1D']);  %%!!  _32W_Healthy
        end
        [measures_funPar_ranked, measures_funPar_ranked_ind] = sort(measures_funPar, 'descend');
        measures_funPar_ranked_ind_names = names_funPar(measures_funPar_ranked_ind);
        if strcmp(group, 'HCP')
            save([outputpath measure label '_Mean_Heatmap_funPar_rankings_' group '.mat'], 'group', 'group_s', 'names_funPar', 'measures_funPar', 'measures_funPar_ranked', 'measures_funPar_ranked_ind', 'measures_funPar_ranked_ind_names');
        else
            save([outputpath measure label '_Mean_twinPick_Heatmap_funPar_rankings_' group '.mat'], 'group', 'group_s', 'names_funPar', 'measures_funPar', 'measures_funPar_ranked', 'measures_funPar_ranked_ind', 'measures_funPar_ranked_ind_names');  %%!!  _32W_Healthy
        end
    end
    %}
    
end

end


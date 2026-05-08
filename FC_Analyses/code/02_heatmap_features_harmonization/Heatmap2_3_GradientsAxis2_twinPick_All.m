clear
clc

mask_inds_file = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-4mm-mask-inds.nii.gz'; %%    %%!!  %%!!  MUST USE MASK!!!!    
nii_mask_inds = load_nii(mask_inds_file);
W_mask_inds = nii_mask_inds.img;

maskfile = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-Yeo8Net-4mm-mask-inds.nii.gz']; % Yeo 8 networks
nii_mask = load_nii(maskfile);
W_mask = nii_mask.img;

%ROIs = {'visualOne','visualTwo','visualThree','DMN','sensoryMotor','auditory','executiveControl','frontoParietalOne','frontoParietalTwo', 'anteriorinsulaR', 'amygdala', 'hippocampus'};  %% 12    %%!!  (omit cerebellum)
%num_ROIs = length(ROIs);

%ROIs = {'visualOne','visualTwo','sensoryMotor','auditory', 'lOFC','amygdala', 'visualThree','DMN','anteriorinsulaR', 'rDLPFC'};  %% 10    %%!!  %%!!  rAI is very weird; keep using anteriorinsulaR instead
%networks = {'V1N','V2N','SMN','AN', 'OFC','AMYG', 'DAN','DMN','SAL', 'CON'};  %% 10    %%!!  
%num_ROIs = length(ROIs); % copied from glab1/Haitao/Add3networks or Smith10networks; only amygdala is defined and used here  

% UNC: UNC 0 1 2 4 6 8 10 in 2yr space
dataset = 'UNC';

measures = {'Gradient12_Var2', 'Gradient12_RanIV2', 'Gradient12_Ran2'};  %%!!    %%!!  run all subjects together: McorrZ / McosSim2 / Str(_8mm2) / Enodal(_8mm2) / Elocal(_8mm2) / TGradient1 / Gradient1_AlignedToFouryear / Gradient2_AlignedToFouryear 
ROIs = {'Gradient1', 'Gradient2'};  %% 2    %%!!  %%!!  Gradient1: Sensorimotor-Visual; Gradient2: Primary-Transmodel    
networks = {'Gradient1', 'Gradient2'};  %% 2    %%!!  updated!!  
num_ROIs = length(ROIs); % 
Colors = [0 114 189; 217 83 25] / 255;  %%!!  RGB values for Gradient1/2  
Cov_label = '';  %%!!    %%!!  ''(original) / '_Harmo'  %%!!    %%!!  _Harmo

ylims = [0,4; 0,6; 0,12];  %%!!    %%!!    %%!!  
groups = {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear', 'HCP'};  %%!!  
groups_s = {'0', '1', '2', '4', '6', '8', '10', 'HCP'};  %%!!  
%clust_thrs = {'15.9', '16.0', '14.6', '12.1', '12.2', '7.3', '6.7'};  %% all groups (N=356/262/212/123/165/153/148); alpha=0.05(bi-sided,NN=1), p=p_thr. FD='_0.3mm',threshold=90   %%!! 

for mm = 1:length(measures)  %%!!  
    measure = measures{mm};
    %inmeasure = measure(1:end-8);  %%!!    %%!!  
    if ismember(measure, {'Str', 'BC', 'Enodal', 'Elocal'})  %%!!  %%!!  graph measures
        label = '_8mm2';  %%!!    %%!!  _8mm2
    else
        label = '';  %%!!  
    end

for gg = 1:length(groups)

%clust_thr = clust_thrs{gg};
FD = '_0.3mm'; %% 0.3mm:'_0.3mm' or 0.5mm:'_0.5mm' 
%threshold = 90;  %%  notr90 
%p_thr = '0.001';  %% bi-sided 
group = groups{gg};
group_s = groups_s{gg};

% load(['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/M_FC_Z_Covs_twinPick_All/M_FC_Z_Covs_twinPick_All_0.3mm_notr90_UNC_' group '.mat']);  %%!!  C as Covariates  
% C = C(:, 5:10);  %%!!    %%!!  Partially DeCov for scanner(based on scanner 2, 4 other categories), meanFD and scan-length (centered) here    

%datapath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/New_heatmaps_results/' measure label '/'];   %%!!    
datapath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/'];   %%!!      %%!!  
outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/barplots_results/' measure label Cov_label '/'];   %%!!   %%!!  
if ~exist(outputpath, 'dir')
    mkdir(outputpath);
end
if strcmp(group, 'HCP')
    subjects = importSubjIDs(['/media/zhark2/glab3/HCP/lists/' group_s '_list_gsr_notr1500_CB.txt']);  %%!!  
else
    subjects = importSubjIDs(['/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists_0.3mm/' group_s '_full_subject_updated_final_twinPick.txt']);  %%!!    %%!!  All  
end
num_subj = length(subjects);

% already harmonized  

datadir = [datapath];  %%!!  %%!!  
%outdir = [outputpath group '/'];  %%!!  
%if ~exist(outdir, 'dir')
%    mkdir(outdir);
%end

measures_network = zeros(num_subj, num_ROIs); %% _original
for ss = 1:num_subj  %%!!  
    subj = subjects{ss};
    % measure  
    for rr = 1:num_ROIs
        ROI = ROIs{rr};
        network = networks{rr};  %%!!  only used for visualization  
        %datadir = [datapath 'Gradient' num2str(rr) '_AlignedToFouryear_NoScale' label Cov_label '/' group '/'];  %%!!  
        infile = [datadir 'Gradient' num2str(rr) '_AlignedToHCP' label Cov_label '/' group '/' subj '_Gradient' num2str(rr) '_AlignedToHCP_Heatmap_' group Cov_label '.nii.gz'];  %%!!    %%!!  
        nii = load_nii(infile);
        W = nii.img;
        V = W(W_mask_inds~=0);  %%!!  %%!!  MUST USE MASK!!!!    %%!!  %%!!  
        if strcmp(measure, 'Gradient12_Var2')  %%!!  
            measure_network = var(V);
        elseif strcmp(measure, 'Gradient12_RanIV2')  %%!!  
            measure_network = prctile(V, 95) - prctile(V, 5);
        elseif strcmp(measure, 'Gradient12_Ran2')  %%!!  
            measure_network = range(V);  %%!!  %%!!  max(V) - min(V)    
        end
        measures_network(ss, rr) = measure_network; %% _original
    end
end
% measures_network = zeros(num_subj, num_ROIs); %% 
% for rr = 1:num_ROIs  %%!!  %%!!  
%     y = squeeze(measures_network_original(:, rr));
%     [B,~,R] = regress(y, [ones(size(C, 1), 1), C]);  %%!!  
%     y_PDeCov = B(1) + R;  %%!!  
%     measures_network(:, rr) = y_PDeCov;
% end

measures_network_mean = mean(measures_network, 1);
measures_network_sem = std(measures_network, 1) / sqrt(size(measures_network, 1));
[~, rank_inds] = sort(measures_network_mean, 'descend');  %%!!  
measures_network_mean_ranked = measures_network_mean(rank_inds);
measures_network_sem_ranked = measures_network_sem(rank_inds);
networks_ranked = networks(rank_inds);
if strcmp(group, 'HCP')
    outfile0 = [outputpath measure label '_Mean_Heatmap_' group Cov_label '.mat'];  %%!!    %%!!  
else
    outfile0 = [outputpath measure label '_Mean_twinPick_Heatmap_' group Cov_label '.mat'];  %%!!    %%!!  _32W_Healthy
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
    outfile1 = [outputpath measure label '_Mean_twinPick_Heatmap_Ranked_Bar_' group Cov_label '.fig'];  %%!!    %%!!  _32W_Healthy
end
saveas(gcf, outfile1);  %%!!  
if strcmp(group, 'HCP')
    outfile2 = [outputpath measure label '_Mean_Heatmap_Ranked_Bar_' group Cov_label '.png'];  %%!!    %%!!  
else
    outfile2 = [outputpath measure label '_Mean_twinPick_Heatmap_Ranked_Bar_' group Cov_label '.png'];  %%!!    %%!!  _32W_Healthy
end
saveas(gcf, outfile2);  %%!!  
close; %% 

end

end


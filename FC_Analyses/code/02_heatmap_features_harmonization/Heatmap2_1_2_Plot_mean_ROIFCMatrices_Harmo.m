clear
clc

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

outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/' measure label '_Harmo/'];   %%!!   %%!!  
if ~exist(outputpath, 'dir')
    mkdir(outputpath);
end
load([outputpath 'funpar_8Net_allinfo.mat']);  %%!!  

if strcmp(group, 'HCP')
    outfile_mean1 = [outputpath group '_mean_FC_M_Harmo.1D'];  %%!!  matrix
else
    outfile_mean1 = [outputpath group '_mean_twinPick_32W_Healthy_FC_M_Harmo.1D'];  %%!!  matrix
end
if exist(outfile_mean1, 'file')
    M_mean = load(outfile_mean1);  %%!!  
    M_mean_grouped = M_mean(group_inds, group_inds);  %%!!  %%!!  
    imagesc(M_mean_grouped); 
    colorbar;
    caxis([-1 1]); % Set the colorbar limits
    title([group ' mean Grouped FC Matrix']);
    if strcmp(group, 'HCP')
        outfile_f = [outputpath group '_mean_Grouped_FC_M_Harmo.png'];  %%!!  figure
    else
        outfile_f = [outputpath group '_mean_Grouped_twinPick_32W_Healthy_FC_M_Harmo.png'];  %%!!  figure
    end
    saveas(gcf, outfile_f);
    close(gcf);
end

end

end

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

Colors = [120 18 134; 70 130 180; 0 118 14; 196 58 250; 206 220 46; 230 148 34; 205 62 78; 128 128 128] / 255;  %%!!  RGB values for Yeo 8 networks  (220 248 164) Changed Limbic!!  

graph_label = '_8mm2';  %%!!    %%!!  _funPar or _8mm or _8mm2  %%!!    %%!!  
%measures = {'PeakFre', 'RMSSD', 'Iron', 'McorrZ', 'Str', 'BC', 'Enodal', 'Elocal',  'PeakFre1', 'Str1', 'BC1', 'Enodal1', 'Elocal1',  'Iron1'};  %%!!    %%!!  
%ylims = [0.02,0.06; 0.3,1.1; -10,18; 0.1,0.55; 15,45; 50,400; 0.15,0.35; 0.1,0.22; 0.02,0.06; 10,55; 100,350; 0.3,0.6; 0.5,0.8; -18,10];  %%!!    %%!!  
measures = {'Gradients'};  %%!!    %%!!    %%!!  
%ylims = [-6,8; -6,8];  %%!!    %%!!    %%!!  

for mm=1:length(measures)
    measure = measures{mm};

groups = {'HCP', 'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear'};
groups_s = {'HCP', '0', '1', '2', '4', '6', '8', '10'};

if ismember(measure, {'Str', 'BC', 'Enodal', 'Elocal',  'Str1', 'BC1', 'Enodal1', 'Elocal1'})  %%!!  %%!!  graph measures
    label = graph_label;  %%!!  
else
    label = '';  %%!!  
end

datapath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Gradient0_Gradients_results_ref_dm/Gradients_results_AlignedToHCP/'];  %%!!  Original MeanHeatmaps  _ref_dm
outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Gradient0_Gradients_results_ref_dm/Gradients_results_AlignedToHCP/gradientsplots_results/'];  %%!!  %%!!  _ref_dm
if ~exist(outputpath, 'dir')
    mkdir(outputpath);
end

align_labels = {'', '_AlignedToHCP'};
for ll = 1:length(align_labels)
    align_label = align_labels{ll};

for gg = 1:length(groups)
    group = groups{gg};
    group_s = groups_s{gg};
    datadir = [datapath];  %%!!  
    %measures_network = zeros(1, num_ROIs);  %%!!  
    if strcmp(group, 'HCP')
        infile1 = [datadir group '_mean_FC_M_Gradient1' align_label '.nii.gz'];  %%!!  
        infile2 = [datadir group '_mean_FC_M_Gradient2' align_label '.nii.gz'];  %%!!  
    else
        infile1 = [datadir group '_twinPick_32W_Healthy_mean_FC_M_Gradient1' align_label '.nii.gz'];  %%!!  
        infile2 = [datadir group '_twinPick_32W_Healthy_mean_FC_M_Gradient2' align_label '.nii.gz'];  %%!!  
    end
    nii1 = load_nii(infile1);
    W1 = nii1.img;
    nii2 = load_nii(infile2);
    W2 = nii2.img;
    figure;
    hold on
    for rr = 1:num_ROIs
        ROI = ROIs{rr};
        network = networks{rr};  %%!!  only used for visualization  
        Color = Colors(rr, :);
        Gradient1_network = W1(W_mask==rr & W_mask_inds~=0);  %%!!  %%!!  MUST USE MASK!!!!    %%!!  %%!!  
        Gradient2_network = W2(W_mask==rr & W_mask_inds~=0);  %%!!  %%!!  MUST USE MASK!!!!    %%!!  %%!!  

            xx = Gradient1_network;  %%!!  
            yy = Gradient2_network;  %%!!  
            xxlabel = 'Gradient1: Sensorimotor-to-Visual';
            yylabel = 'Gradient2: Primary-to-Transmodal';  %%!!  
        
        scatter(xx, yy, 3, Color, 'filled', 'o');  %%!!  %%!!  
    end
    xlim([-10, 15]);
    ylim([-10, 10]);  %%!!  
    xlabel(xxlabel);
    ylabel(yylabel);
    grid;
    set(gca, 'fontsize', 15);  %%!!  
    set(gca, 'YDir', 'reverse');  %%!!  reverse Transmodal-to-Primary to Primary-to-Transmodal
    %axis equal
    hold off
    if strcmp(group, 'HCP')
        outfile1 = [outputpath measure label '_MeanHeatmap_Plot_' group align_label '.fig'];  %%!!  
    else
        outfile1 = [outputpath measure label '_twinPick_32W_Healthy_MeanHeatmap_Plot_' group align_label '.fig'];  %%!!  
    end
    saveas(gcf, outfile1);  %%!!  
    if strcmp(group, 'HCP')
        outfile2 = [outputpath measure label '_MeanHeatmap_Plot_' group align_label '.png'];  %%!!  
    else
        outfile2 = [outputpath measure label '_twinPick_32W_Healthy_MeanHeatmap_Plot_' group align_label '.png'];  %%!!  
    end
    saveas(gcf, outfile2);  %%!!  
    close; %% 
    
end

end

end



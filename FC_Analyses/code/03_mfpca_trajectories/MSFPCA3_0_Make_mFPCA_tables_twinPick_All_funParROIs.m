clear
clc

measures = {'McosSim2' 'Str', 'Enodal', 'Elocal', 'Gradient1_AlignedToHCP', 'Gradient2_AlignedToHCP'};  %%!!    %%!!  run all subjects together: McorrZ / McosSim2 / Str(_8mm2) / Enodal(_8mm2) / Elocal(_8mm2) / TGradient1 / Gradient1_AlignedToHCP / Gradient2_AlignedToHCP 
%  , 'Gradient12_Var2', 'Gradient12_RanIV2', 'GradientsDispW', 'GradientsDispN', 'GradientsDispW2', 'GradientsDispN2'
dataset = 'UNC';
Cov_label = '_Harmo';  %%!!    %%!!  ''(original) / '_Harmo'  %%!!    %%!!  
groups = {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear', 'HCP'};  %%!!  
groups_s = {'0', '1', '2', '4', '6', '8', '10', 'HCP'};  %%!!  
groups_o = {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear', 'HCP_2yrspace_4mm'};  %%!!  

level = 'ROIs';  %%!!  %%!!  

for mm=1:length(measures)  %%!!  %%!!  
    measure = measures{mm};

    if ismember(measure, {'Str', 'BC', 'Enodal', 'Elocal'})  %%!!  %%!!  graph measures
        label = '_8mm2';  %%!!    %%!!  _8mm2
    else
        label = '';  %%!!  
    end
    
    datapath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/barplots_results_' level '/' measure label Cov_label '/'];  %%!!  %%!!  
    outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/MSFPCA3_New_tables_results/M_FC_Z_' level '_' measure label Cov_label '_twinPick_All/'];  %%!!  %%!!    %%!!  
    if ~exist(outputpath, 'dir')
        mkdir(outputpath);
    end
    
    for gg = 1:length(groups)
        FD = '_0.3mm'; %% 0.3mm:'_0.3mm' or 0.5mm:'_0.5mm' 
        threshold = 90;  %%  notr90 
        group = groups{gg};
        group_s = groups_s{gg};
        group_o = groups_o{gg};
        if strcmp(group, 'HCP')
            subjects = importSubjIDs(['/media/zhark2/glab3/HCP/lists/HCP_list_gsr_notr1500_CB.txt']);  %%!!    
        else
            subjects = importSubjIDs(['/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists_0.3mm/' group_s '_full_subject_updated_final_twinPick.txt']);  %%!!    %%!!  All  
        end
        num_subj = length(subjects);
        if strcmp(group, 'HCP')
            infile = [datapath measure label '_Mean_Heatmap_' group Cov_label '.mat'];  %%!!    %%!!  
        else
            infile = [datapath measure label '_Mean_twinPick_Heatmap_' group Cov_label '.mat'];  %%!!  _32W_Healthy  %%!!  
        end
        outfile = [outputpath 'M_FC_Z_' level '_' measure label Cov_label '_twinPick_All' FD '_notr' num2str(threshold) '_' dataset '_' group_o '.mat'];  %%!!  %%!!    %%!!  
        outfile1 = [outputpath 'M_FC_Z_' level '_' measure label Cov_label '_twinPick_All' FD '_notr' num2str(threshold) '_' dataset '_' group_o '.csv'];  %%!!  %%!!    %%!!  
        %if ~exist(outfile, 'file')
            load(infile);
            M_FC_Z = measures_ROI;  %%!!  %%!!  
            labels = ROIs;  %%!!  %%!!  
            M_FC_Z_whole = ['Subjects', labels; subjects, num2cell(M_FC_Z)];
            save(outfile, 'M_FC_Z', 'labels', 'subjects', 'M_FC_Z_whole');  
            T = array2table(M_FC_Z_whole);
            writetable(T, outfile1, 'WriteVariableNames', false);
        %end
    end
end

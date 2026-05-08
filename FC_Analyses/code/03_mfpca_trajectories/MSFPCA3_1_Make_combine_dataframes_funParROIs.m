clear
clc

measures = {'McosSim2' 'Str', 'Enodal', 'Elocal', 'Gradient1_AlignedToHCP', 'Gradient2_AlignedToHCP'};  %%!!    %%!!  run all subjects together: McorrZ / McosSim2 / Str(_8mm2) / Enodal(_8mm2) / Elocal(_8mm2) / TGradient1 / Gradient1_AlignedToHCP / Gradient2_AlignedToHCP 
%  , 'Gradient12_Var2', 'Gradient12_RanIV2', 'GradientsDispW', 'GradientsDispN', 'GradientsDispW2', 'GradientsDispN2'
dataset = 'UNC';
Cov_label = '_Harmo';  %%!!    %%!!  ''(original) / '_Harmo'  %%!!    %%!!  
ages = {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear'};  %%!!  
ages_num = [0, 1, 2, 4, 6, 8, 10];  %%!!  

level = 'ROIs';  %%!!  %%!!  

for mm=1:length(measures)  %%!!  %%!!  
    measure = measures{mm};

    if ismember(measure, {'Str', 'BC', 'Enodal', 'Elocal'})  %%!!  %%!!  graph measures
        label = '_8mm2';  %%!!    %%!!  _8mm2
    else
        label = '';  %%!!  
    end
    
    datapath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/MSFPCA3_New_tables_results/M_FC_Z_' level '_' measure label Cov_label '_twinPick_All/'];  %%!!  %%!!    %%!!  
    lists_path = ['/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists_0.3mm/'];
    [~,~,data] = xlsread([lists_path 'WholeSubjectList_All_Final_849Subjects_updated_preprocessing_20240718.xlsx']);  %%!!  updated!!    %%!!  
    subjects_all = data(2:end,1); 
    GAS = cell2mat(data(2:end,130:136));  %%!!  

    M_FC_Z_combined = {};
    for aa = 1:length(ages)
        age = ages{aa};
        age_num = ages_num(aa);
        load([datapath 'M_FC_Z_' level '_' measure label Cov_label '_twinPick_All_0.3mm_notr90_' dataset '_' age '.mat']);  %%!!  
        AgeYear = num2cell(age_num*ones(size(M_FC_Z_whole, 1), 1));
        AgeYear{1} = 'AgeYear';
        GASDay = cell(size(M_FC_Z_whole, 1), 1);
        GASDay{1} = 'GASDay';
        for ss = 1:length(subjects)
            subj = subjects{ss};
            ind = find(strcmp(subjects_all, subj));
            GASDay{ss+1} = GAS(ind, aa);
        end
        M_FC_Z_added = [AgeYear, GASDay, M_FC_Z_whole];  %%!!  
        if aa == 1
            M_FC_Z_combined = [M_FC_Z_combined; M_FC_Z_added];
        else
            M_FC_Z_combined = [M_FC_Z_combined; M_FC_Z_added(2:end, :)];
        end
    end
    save([datapath 'M_FC_Z_' level '_' measure label Cov_label '_twinPick_All_0.3mm_notr90_' dataset '_added_combined.mat'], 'M_FC_Z_combined');  %%!!  
    T = array2table(M_FC_Z_combined);
    writetable(T, [datapath 'M_FC_Z_' level '_' measure label Cov_label '_twinPick_All_0.3mm_notr90_' dataset '_added_combined.csv'], 'WriteVariableNames', false);  %%!!  

end



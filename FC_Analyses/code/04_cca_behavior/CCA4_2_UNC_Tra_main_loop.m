clear
clc

set(groot, 'defaultTextInterpreter', 'none');  %%!!  %%!!  enable '_'

addpath('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/cca_pls_toolkit/');  %%!!  

measures_YR = {'4', '6', '8', '10'};  %%!!  {'4', '6', '8', '10'} for IQ/ANX/DEP, {'1', '2'} for Mul
for YY = 1:length(measures_YR)
    measure_YR = measures_YR{YY};

ages = {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear'};  %%!!  
ages_num = [0, 1, 2, 4, 6, 8, 10];  %%!!  
Ys_label = {['AllCognition1' measure_YR], ['AllCognition2' measure_YR]};  %%!!  {['MulSubs' measure_YR], ['MulCom' measure_YR]}
% ['IQ' measure_YR], ['Anxiety' measure_YR], ['Depression' measure_YR],
% ['AllEmotion' measure_YR], ['AllBehavior' measure_YR], ['WM_SB' measure_YR], ['WM_BRIEF' measure_YR]
levels = {'Dev_ROIs_all'};  %%!!  'FC_Matrices', 'ROIs', 'Networks', 'ROIs_all', 'Networks_all',  'Dev_ROIs_all', 'AbsDev_ROIs_all'
for ll = 1:length(levels)  %%!!  
    level = levels{ll};
    if strcmp(level, 'FC_Matrices')
        measures = {'funPar_Harmo'};  %%!!  %%!!   
    elseif ismember(level, {'ROIs', 'Networks'})
        measures = {'Str_8mm2_Harmo', 'Enodal_8mm2_Harmo', 'Elocal_8mm2_Harmo', 'McosSim2_Harmo', 'Gradient1_AlignedToHCP_Harmo', 'Gradient2_AlignedToHCP_Harmo'};  %%!!  %%!!  
    elseif ismember(level, {'ROIs_all', 'Networks_all',  'Dev_ROIs_all', 'AbsDev_ROIs_all'})  %%!!  %%!!  
        measures = {'All_Harmo'};  %%!!  %%!!   
    end
    for mm = 1:length(measures)
        measure = measures{mm};
        for aa = 1:length(ages)  %%!!  3:4%
            age = ages{aa};
            age_num = ages_num(aa);
            for yy = 1:length(Ys_label)
                Y_label = Ys_label{yy};

                disp([level, '_', measure, ' ', age, ' ', Y_label, ':']);  %%!!  

                %CCA4_1_UNC_Tra_Desc(level, measure, age, age_num, Y_label);  %%!!  
                CCA4_1_UNC_Tra_Pred(level, measure, age, age_num, Y_label);  %%!!  

            end
        end
    end

end

end


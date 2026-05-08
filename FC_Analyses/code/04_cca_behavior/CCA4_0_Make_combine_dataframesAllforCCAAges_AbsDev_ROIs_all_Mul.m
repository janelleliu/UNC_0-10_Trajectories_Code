clear
clc

measures_YR = {'1', '2'};
measures_col = [146, 172];  %%!!  %%!!  only for 1/2 Mullen Subscores / Composite    
for YY = 1:length(measures_YR)
    measure_YR = measures_YR{YY};
    measure_col = measures_col(YY);

mask_inds_file = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-4mm-mask-inds.nii.gz'; %%    %%!!  %%!!  MUST USE MASK!!!!    
nii_mask_inds = load_nii(mask_inds_file);
W_mask_inds = nii_mask_inds.img;

groups = {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear'};  %%!!  , 'HCP'
groups_s = {'0', '1', '2', '4', '6', '8', '10'};  %%!!  , 'HCP'

level = 'AbsDev_ROIs_all';  %%!!  %%!!  Absolute Deviation scores abs((y-y_norm)/std_norm), 2yr funPar 278 ROIs, all sub-measures
load('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/names_aal.mat');  %%!!  
funPar_aal_inds = load('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/2yr-index-conversion_c.txt');  %%!!  
names_funPar = names_90ROIs(funPar_aal_inds);  %%!!  %%!!  
num_ROIs = length(names_funPar);  %%!!  2yr funPar 278 ROIs
maskfile = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-funPar-4mm-mask-inds.nii.gz']; % 2yr funPar 278 ROIs  %%!!  %%!!  
nii_mask = load_nii(maskfile);
W_mask = nii_mask.img;
measures = {'All'};  %%!!  %%!!  
sub_measures = {'Str', 'Enodal', 'Elocal', 'McosSim2', 'Gradient1_AlignedToHCP', 'Gradient2_AlignedToHCP'};  %%!!  %%!!  
num_sub_measures = length(sub_measures);
for mm = 1:length(measures)
    measure = measures{mm};
    if ismember(measure, {'Str', 'BC', 'Enodal', 'Elocal'})  %%!!  %%!!  graph measures
        label = '_8mm2';  %%!!  
    else
        label = '';  %%!!  
    end
    Cov_label = '_Harmo';  %%!!    %%!!  ''(original) / '_Harmo'  %%!!    %%!!  _Harmo for barplots and tests

    datapath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/'];  %%!!    %%!!  
    outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/CCA4_M_FC_Z_All_for_CCA_Ages/'];  %%!!    %%!!  
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
        GAAssess_all = data(2:end, measure_col);  %%!!    %%!!  
        MulSubs_all = cell2mat(data(2:end, measure_col+3:4:measure_col+19));  %%!!  
        MulSubs_labels = data(1, measure_col+3:4:measure_col+19);  %%!!  
        MulCom_all = cell2mat(data(2:end, measure_col+22));  %%!!  
        MulCom_labels = data(1, measure_col+22);  %%!!  
        [subjects_all, inds_all] = sort(subjects_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
        Medu_all = Medu_all(inds_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
        GAAssess_all = GAAssess_all(inds_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
        MulSubs_all = MulSubs_all(inds_all, :);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        %%!!  %%!!  
        MulCom_all = MulCom_all(inds_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
        subjects_twinPick_All = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick.txt']);  %%!!    %%!!  All  
        subjects_twinPick_Normal = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_32W_Healthy.txt']);  %%!!    %%!!  Normal  
        subjects_twinPick_NDD = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_ADAU.txt']);  %%!!    %%!!  NDD  
        subjects_twinPick_MPD = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_MaternalPD.txt']);  %%!!    %%!!  MPD  
        cov_file = [covpath 'M_FC_Z_Covs_twinPick_All_0.3mm_notr90_UNC_' group '.mat'];
        load(cov_file);  %%!!  C as categorized/centered GAB+GAS+BW+Sex +Scanner+MeanFD+ScanLength
        CC = C(:, 1:4);  %%!!  CC as categorized/centered GAB+GAS+BW+Sex for subjects_twinPick_All  %%!!  %%!!  
        subjects = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick.txt']);  %%!!    %%!!  All  
        num_subj = length(subjects);
        measures_feature = zeros(num_subj, num_ROIs*num_sub_measures);  %%!!  %%!!  
        for sm = 1:num_sub_measures
            sub_measure = sub_measures{sm};
            if ismember(sub_measure, {'Str', 'BC', 'Enodal', 'Elocal'})  %%!!  %%!!  graph measures
                sub_label = '_8mm2';  %%!!  
            else
                sub_label = '';  %%!!  
            end
            sub_Cov_label = '_Harmo';  %%!!    %%!!  ''(original) / '_Harmo'  %%!!    %%!!  _Harmo for barplots and tests
            datadir = [datapath sub_measure sub_label sub_Cov_label '/' group '/'];
            for ss = 1:num_subj
                subj = subjects{ss};
                infile = [datadir subj '_' sub_measure '_Heatmap_' group sub_Cov_label '.nii.gz'];  %%!!    %%!!  
                nii = load_nii(infile);
                W = nii.img;
                for rr = 1:num_ROIs
                    measure_feature = mean(W(W_mask==rr & W_mask_inds~=0));  %%!!  %%!!  MUST USE MASK!!!!    %%!!  %%!!  
                    measures_feature(ss, num_ROIs*(sm-1)+rr) = measure_feature;  %%!!  %%!!  
                end
            end
        end
        
        normpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/MSFPCA3_New_tables_results/mFPCA/mfpca_plot_results_Reconstruct_ROIs/'];
        measures_feature_norm = zeros(num_subj, num_ROIs*num_sub_measures);  %%!!  %%!!  
        measures_feature_std_norm = zeros(num_subj, num_ROIs*num_sub_measures);  %%!!  %%!!  
        for sm = 1:num_sub_measures
            sub_measure = sub_measures{sm};
            if ismember(sub_measure, {'Str', 'BC', 'Enodal', 'Elocal'})  %%!!  %%!!  graph measures
                sub_label = '_8mm2';  %%!!  
            else
                sub_label = '';  %%!!  
            end
            sub_Cov_label = '_Harmo';  %%!!    %%!!  ''(original) / '_Harmo'  %%!!    %%!!  _Harmo for barplots and tests
            normfile = [normpath 'Mean_mFPCA_' sub_measure sub_label sub_Cov_label '_twinPick_Normal_M_Original_0.3mm_notr90_UNC.mat'];
            load(normfile); %% X_GAS_Day; Individual_Curves_Mean_twinPick_Normal; Individual_Curves_Std_twinPick_Normal
            for ss = 1:num_subj
                subj = subjects{ss};
                x_GAS = C_raw(ss, 2);  %%!!  %%!!  
                for rr = 1:num_ROIs
                    measure_feature_norm = interp1(X_GAS_Day, Individual_Curves_Mean_twinPick_Normal(:, rr), x_GAS, 'spline');  %%!!  %%!!  
                    measure_feature_std_norm = interp1(X_GAS_Day, Individual_Curves_Std_twinPick_Normal(:, rr), x_GAS, 'spline');  %%!!  %%!!  
                    measures_feature_norm(ss, num_ROIs*(sm-1)+rr) = measure_feature_norm;  %%!!  %%!!  
                    measures_feature_std_norm(ss, num_ROIs*(sm-1)+rr) = measure_feature_std_norm;  %%!!  %%!!  
                end
            end
        end
        measures_feature_AbsDev = abs((measures_feature - measures_feature_norm) ./ measures_feature_std_norm);  %%!!  %%!!  

        subjects_twinPick_MulCom = intersect(subjects_twinPick_All, subjects_all(~isnan(MulCom_all)));  %%!!  twinPick with Mullen Composite  %%!!  
        Medu_twinPick_MulCom = Medu_all(ismember(subjects_all, subjects_twinPick_MulCom));  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
        subjects_twinPick_MulCom_withMedu = subjects_twinPick_MulCom(~isnan(Medu_twinPick_MulCom));  %%!!  with MulCom & with Medu  %%!!  
        Medu_twinPick_MulCom_withMedu = Medu_all(ismember(subjects_all, subjects_twinPick_MulCom_withMedu));  %%!!    %%!!  
        Medu_twinPick_MulCom_withMedu = Medu_twinPick_MulCom_withMedu - mean(Medu_twinPick_MulCom_withMedu);  %%!!    %%!!  centered
        NDD_twinPick_MulCom_withMedu = double(ismember(subjects_twinPick_MulCom_withMedu, subjects_twinPick_NDD));  %%!!    %%!!  categorized
        MPD_twinPick_MulCom_withMedu = double(ismember(subjects_twinPick_MulCom_withMedu, subjects_twinPick_MPD));  %%!!    %%!!  categorized
        GAAssess_twinPick_MulCom_withMedu = cell2mat(GAAssess_all(ismember(subjects_all, subjects_twinPick_MulCom_withMedu)));  %%!!    %%!!  
        GAAssess_twinPick_MulCom_withMedu = GAAssess_twinPick_MulCom_withMedu - mean(GAAssess_twinPick_MulCom_withMedu);  %%!!    %%!!  centered
        C_twinPick_MulCom_withMedu = CC(ismember(subjects_twinPick_All, subjects_twinPick_MulCom_withMedu), :);  %%!!    %%!!  categorized/centered GAB+GAS+BW+Sex for subjects_twinPick_AllBehavior_withMedu  %%!!  %%!!  
        C_twinPick_MulCom_withMedu = [C_twinPick_MulCom_withMedu, Medu_twinPick_MulCom_withMedu, NDD_twinPick_MulCom_withMedu, MPD_twinPick_MulCom_withMedu, GAAssess_twinPick_MulCom_withMedu];  %%!!    %%!!  All covs for longitudinal regression test (except for intercept 1+)
        MulSubs_twinPick_MulCom_withMedu = MulSubs_all(ismember(subjects_all, subjects_twinPick_MulCom_withMedu), :);  %%!!    %%!!  no need to center  %%!!  %%!!  
        MulCom_twinPick_MulCom_withMedu = MulCom_all(ismember(subjects_all, subjects_twinPick_MulCom_withMedu));  %%!!    %%!!  no need to center
        measures_feature_AbsDev_twinPick_MulCom_withMedu = measures_feature_AbsDev(ismember(subjects_twinPick_All, subjects_twinPick_MulCom_withMedu), :);  %%!!  %%!!  Modify
        
        X = measures_feature_AbsDev_twinPick_MulCom_withMedu;  %%!!  %%!!  Modify
        Y = MulSubs_twinPick_MulCom_withMedu;  %%!!  %%!!  
        C = C_twinPick_MulCom_withMedu;  %%!!  
        outdir = [outputpath 'MulSubs' measure_YR '_' level '_' measure label Cov_label '_' group '/data/'];  %%!!  %%!!  
        if ~exist(outdir, 'dir')
            mkdir(outdir);
        end
        save([outdir 'X.mat'], 'X');
        save([outdir 'Y.mat'], 'Y');
        save([outdir 'C.mat'], 'C');
        
        X = measures_feature_AbsDev_twinPick_MulCom_withMedu;  %%!!  %%!!  Modify
        Y = MulCom_twinPick_MulCom_withMedu;  %%!!  %%!!  
        C = C_twinPick_MulCom_withMedu;  %%!!  
        outdir = [outputpath 'MulCom' measure_YR '_' level '_' measure label Cov_label '_' group '/data/'];  %%!!  %%!!  
        if ~exist(outdir, 'dir')
            mkdir(outdir);
        end
        save([outdir 'X.mat'], 'X');
        save([outdir 'Y.mat'], 'Y');
        save([outdir 'C.mat'], 'C');
        
    end
    
    % make LabelsX_measure.csv
    L = cell(1 + size(X, 2), 4);
    L(1, :) = {'Label', 'Category', 'Label_proc', 'Label_bold'};
    labelsX = repmat(names_funPar', 1, num_sub_measures);  %%!!  %%!!  
    for xx = 1:size(X, 2)
        sm = ceil(xx / num_ROIs);  %%!!  %%!!  
        sub_measure = sub_measures{sm};  %%!!  
        labelX = labelsX{xx};  %%!!  
        L{1 + xx, 1} = labelX; %% 
        L{1 + xx, 2} = sub_measure; %% network  %%!!  
        L{1 + xx, 3} = labelX; %% 
        L{1 + xx, 4} = labelX; %% 
    end
    T = array2table(L); %% 
    writetable(T, [outputpath 'LabelsX_' level '_' measure label Cov_label '.csv'], 'WriteVariableNames', false);  %%!!  %%!!  
    
end

% make LabelsY_measure.csv
L = cell(1 + length(MulSubs_labels), 4);  %%!!  %%!!  
L(1, :) = {'Label', 'Category', 'Label_proc', 'Label_bold'};
labelsY = MulSubs_labels;  %%!!  %%!!  Gross Motor, Visual Reception, Fine Motor, Receptive Language, Expressive Language
groupsY = {['Motor_' measure_YR 'YR'], ['Cognitive_' measure_YR 'YR'], ['Motor_' measure_YR 'YR'], ['Language_' measure_YR 'YR'], ['Language_' measure_YR 'YR']};  %%!!  %%!!  
for yy = 1:length(MulSubs_labels)  %%!!  %%!!  
    labelY = labelsY{yy};  %%!!  
    groupY = groupsY{yy};  %%!!  
    L{1 + yy, 1} = labelY; %% 
    L{1 + yy, 2} = groupY; %% network
    L{1 + yy, 3} = labelY; %% 
    L{1 + yy, 4} = labelY; %% 
end
T = array2table(L); %% 
writetable(T, [outputpath 'LabelsY_MulSubs' measure_YR '.csv'], 'WriteVariableNames', false);  %%!!  %%!!  

% make LabelsY_measure.csv
L = cell(1 + length(MulCom_labels), 4);  %%!!  %%!!  
L(1, :) = {'Label', 'Category', 'Label_proc', 'Label_bold'};
labelsY = MulCom_labels;  %%!!  %%!!  Mullen Composite
groupsY = {['MullenComposite_' measure_YR 'YR']};  %%!!  %%!!  
for yy = 1:length(MulCom_labels)  %%!!  %%!!  
    labelY = labelsY{yy};  %%!!  
    groupY = groupsY{yy};  %%!!  
    L{1 + yy, 1} = labelY; %% 
    L{1 + yy, 2} = groupY; %% network
    L{1 + yy, 3} = labelY; %% 
    L{1 + yy, 4} = labelY; %% 
end
T = array2table(L); %% 
writetable(T, [outputpath 'LabelsY_MulCom' measure_YR '.csv'], 'WriteVariableNames', false);  %%!!  %%!!  

end


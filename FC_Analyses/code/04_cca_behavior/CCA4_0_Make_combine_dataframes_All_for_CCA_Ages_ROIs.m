clear
clc

mask_inds_file = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-4mm-mask-inds.nii.gz'; %%    %%!!  %%!!  MUST USE MASK!!!!    
nii_mask_inds = load_nii(mask_inds_file);
W_mask_inds = nii_mask_inds.img;

groups = {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear'};  %%!!  , 'HCP'
groups_s = {'0', '1', '2', '4', '6', '8', '10'};  %%!!  , 'HCP'

level = 'ROIs';  %%!!  %%!!  2yr funPar 278 ROIs
load('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/names_aal.mat');  %%!!  
funPar_aal_inds = load('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/2yr-index-conversion_c.txt');  %%!!  
names_funPar = names_90ROIs(funPar_aal_inds);  %%!!  %%!!  
num_ROIs = length(names_funPar);  %%!!  2yr funPar 278 ROIs
maskfile = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-funPar-4mm-mask-inds.nii.gz']; % 2yr funPar 278 ROIs  %%!!  %%!!  
nii_mask = load_nii(maskfile);
W_mask = nii_mask.img;
measures = {'Str', 'Enodal', 'Elocal', 'McosSim2', 'Gradient1_AlignedToHCP', 'Gradient2_AlignedToHCP'};  %%!!  %%!!  
for mm = 1:length(measures)
    measure = measures{mm};
    if ismember(measure, {'Str', 'BC', 'Enodal', 'Elocal'})  %%!!  %%!!  graph measures
        label = '_8mm2';  %%!!  
    else
        label = '';  %%!!  
    end
    Cov_label = '_Harmo';  %%!!    %%!!  ''(original) / '_Harmo'  %%!!    %%!!  _Harmo for barplots and tests

    datapath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/' measure label Cov_label '/'];  %%!!    %%!!  
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
        GAAssess10_all = data(2:end, 222);  %%!!    %%!!  
        IQ10_all = cell2mat(data(2:end, 223));  %%!!  
        Anxiety10_all = cell2mat(data(2:end, 224));  %%!!  
        Depression10_all = cell2mat(data(2:end, 225));  %%!!  
        [subjects_all, inds_all] = sort(subjects_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
        Medu_all = Medu_all(inds_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
        GAAssess10_all = GAAssess10_all(inds_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
        IQ10_all = IQ10_all(inds_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
        Anxiety10_all = Anxiety10_all(inds_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
        Depression10_all = Depression10_all(inds_all);  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
        subjects_twinPick_All = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick.txt']);  %%!!    %%!!  All  
        subjects_twinPick_Normal = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_32W_Healthy.txt']);  %%!!    %%!!  Normal  
        subjects_twinPick_NDD = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_ADAU.txt']);  %%!!    %%!!  NDD  
        subjects_twinPick_MPD = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick_MaternalPD.txt']);  %%!!    %%!!  MPD  
        cov_file = [covpath 'M_FC_Z_Covs_twinPick_All_0.3mm_notr90_UNC_' group '.mat'];
        load(cov_file);  %%!!  C as categorized/centered GAB+GAS+BW+Sex +Scanner+MeanFD+ScanLength
        CC = C(:, 1:4);  %%!!  CC as categorized/centered GAB+GAS+BW+Sex for subjects_twinPick_All  %%!!  %%!!  
        datadir = [datapath group '/'];
        subjects = importSubjIDs([listpath group_s '_full_subject_updated_final_twinPick.txt']);  %%!!    %%!!  All  
        num_subj = length(subjects);
        measures_feature = zeros(num_subj, num_ROIs);  %%!!  
        for ss = 1:num_subj
            subj = subjects{ss};
            infile = [datadir subj '_' measure '_Heatmap_' group Cov_label '.nii.gz'];  %%!!    %%!!  
            nii = load_nii(infile);
            W = nii.img;
            for rr = 1:num_ROIs
                measure_feature = mean(W(W_mask==rr & W_mask_inds~=0));  %%!!  %%!!  MUST USE MASK!!!!    %%!!  %%!!  
                measures_feature(ss, rr) = measure_feature;
            end
        end

        subjects_twinPick_IQ10 = intersect(subjects_twinPick_All, subjects_all(~isnan(IQ10_all)));  %%!!  twinPick with IQ10  %%!!  
        Medu_twinPick_IQ10 = Medu_all(ismember(subjects_all, subjects_twinPick_IQ10));  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
        subjects_twinPick_IQ10_withMedu = subjects_twinPick_IQ10(~isnan(Medu_twinPick_IQ10));  %%!!  with IQ10 & with Medu  %%!!  
        Medu_twinPick_IQ10_withMedu = Medu_all(ismember(subjects_all, subjects_twinPick_IQ10_withMedu));  %%!!    %%!!  
        Medu_twinPick_IQ10_withMedu = Medu_twinPick_IQ10_withMedu - mean(Medu_twinPick_IQ10_withMedu);  %%!!    %%!!  centered
        NDD_twinPick_IQ10_withMedu = double(ismember(subjects_twinPick_IQ10_withMedu, subjects_twinPick_NDD));  %%!!    %%!!  categorized
        MPD_twinPick_IQ10_withMedu = double(ismember(subjects_twinPick_IQ10_withMedu, subjects_twinPick_MPD));  %%!!    %%!!  categorized
        GAAssess10_twinPick_IQ10_withMedu = cell2mat(GAAssess10_all(ismember(subjects_all, subjects_twinPick_IQ10_withMedu)));  %%!!    %%!!  
        GAAssess10_twinPick_IQ10_withMedu = GAAssess10_twinPick_IQ10_withMedu - mean(GAAssess10_twinPick_IQ10_withMedu);  %%!!    %%!!  centered
        C_twinPick_IQ10_withMedu = CC(ismember(subjects_twinPick_All, subjects_twinPick_IQ10_withMedu), :);  %%!!    %%!!  categorized/centered GAB+GAS+BW+Sex for subjects_twinPick_IQ10_withMedu  %%!!  %%!!  
        C_twinPick_IQ10_withMedu = [C_twinPick_IQ10_withMedu, Medu_twinPick_IQ10_withMedu, NDD_twinPick_IQ10_withMedu, MPD_twinPick_IQ10_withMedu, GAAssess10_twinPick_IQ10_withMedu];  %%!!    %%!!  All covs for longitudinal regression test (except for intercept 1+)
        IQ10_twinPick_IQ10_withMedu = IQ10_all(ismember(subjects_all, subjects_twinPick_IQ10_withMedu));  %%!!    %%!!  no need to center
        measures_feature_twinPick_IQ10_withMedu = measures_feature(ismember(subjects_twinPick_All, subjects_twinPick_IQ10_withMedu), :);  %%!!  
        X = measures_feature_twinPick_IQ10_withMedu;  %%!!  
        Y = IQ10_twinPick_IQ10_withMedu;  %%!!  
        C = C_twinPick_IQ10_withMedu;  %%!!  
        outdir = [outputpath 'IQ10_' level '_' measure label Cov_label '_' group '/data/'];  %%!!  %%!!  
        if ~exist(outdir, 'dir')
            mkdir(outdir);
        end
        save([outdir 'X.mat'], 'X');
        save([outdir 'Y.mat'], 'Y');
        save([outdir 'C.mat'], 'C');

        subjects_twinPick_Anxiety10 = intersect(subjects_twinPick_All, subjects_all(~isnan(Anxiety10_all)));  %%!!  twinPick with Anxiety10  %%!!  
        Medu_twinPick_Anxiety10 = Medu_all(ismember(subjects_all, subjects_twinPick_Anxiety10));  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
        subjects_twinPick_Anxiety10_withMedu = subjects_twinPick_Anxiety10(~isnan(Medu_twinPick_Anxiety10));  %%!!  with Anxiety10 & with Medu  %%!!  
        Medu_twinPick_Anxiety10_withMedu = Medu_all(ismember(subjects_all, subjects_twinPick_Anxiety10_withMedu));  %%!!    %%!!  
        Medu_twinPick_Anxiety10_withMedu = Medu_twinPick_Anxiety10_withMedu - mean(Medu_twinPick_Anxiety10_withMedu);  %%!!    %%!!  centered
        NDD_twinPick_Anxiety10_withMedu = double(ismember(subjects_twinPick_Anxiety10_withMedu, subjects_twinPick_NDD));  %%!!    %%!!  categorized
        MPD_twinPick_Anxiety10_withMedu = double(ismember(subjects_twinPick_Anxiety10_withMedu, subjects_twinPick_MPD));  %%!!    %%!!  categorized
        GAAssess10_twinPick_Anxiety10_withMedu = cell2mat(GAAssess10_all(ismember(subjects_all, subjects_twinPick_Anxiety10_withMedu)));  %%!!    %%!!  
        GAAssess10_twinPick_Anxiety10_withMedu = GAAssess10_twinPick_Anxiety10_withMedu - mean(GAAssess10_twinPick_Anxiety10_withMedu);  %%!!    %%!!  centered
        C_twinPick_Anxiety10_withMedu = CC(ismember(subjects_twinPick_All, subjects_twinPick_Anxiety10_withMedu), :);  %%!!    %%!!  categorized/centered GAB+GAS+BW+Sex for subjects_twinPick_Anxiety10_withMedu  %%!!  %%!!  
        C_twinPick_Anxiety10_withMedu = [C_twinPick_Anxiety10_withMedu, Medu_twinPick_Anxiety10_withMedu, NDD_twinPick_Anxiety10_withMedu, MPD_twinPick_Anxiety10_withMedu, GAAssess10_twinPick_Anxiety10_withMedu];  %%!!    %%!!  All covs for longitudinal regression test (except for intercept 1+)
        Anxiety10_twinPick_Anxiety10_withMedu = Anxiety10_all(ismember(subjects_all, subjects_twinPick_Anxiety10_withMedu));  %%!!    %%!!  no need to center
        measures_feature_twinPick_Anxiety10_withMedu = measures_feature(ismember(subjects_twinPick_All, subjects_twinPick_Anxiety10_withMedu), :);  %%!!  
        X = measures_feature_twinPick_Anxiety10_withMedu;  %%!!  
        Y = Anxiety10_twinPick_Anxiety10_withMedu;  %%!!  
        C = C_twinPick_Anxiety10_withMedu;  %%!!  
        outdir = [outputpath 'Anxiety10_' level '_' measure label Cov_label '_' group '/data/'];  %%!!  %%!!  
        if ~exist(outdir, 'dir')
            mkdir(outdir);
        end
        save([outdir 'X.mat'], 'X');
        save([outdir 'Y.mat'], 'Y');
        save([outdir 'C.mat'], 'C');

        subjects_twinPick_Depression10 = intersect(subjects_twinPick_All, subjects_all(~isnan(Depression10_all)));  %%!!  twinPick with Depression10  %%!!  
        Medu_twinPick_Depression10 = Medu_all(ismember(subjects_all, subjects_twinPick_Depression10));  %%!!    %%!!  If need IN ORDER by using ISMEMBER, need to SORT every subject list first!!!!!!!!        
        subjects_twinPick_Depression10_withMedu = subjects_twinPick_Depression10(~isnan(Medu_twinPick_Depression10));  %%!!  with Depression10 & with Medu  %%!!  
        Medu_twinPick_Depression10_withMedu = Medu_all(ismember(subjects_all, subjects_twinPick_Depression10_withMedu));  %%!!    %%!!  
        Medu_twinPick_Depression10_withMedu = Medu_twinPick_Depression10_withMedu - mean(Medu_twinPick_Depression10_withMedu);  %%!!    %%!!  centered
        NDD_twinPick_Depression10_withMedu = double(ismember(subjects_twinPick_Depression10_withMedu, subjects_twinPick_NDD));  %%!!    %%!!  categorized
        MPD_twinPick_Depression10_withMedu = double(ismember(subjects_twinPick_Depression10_withMedu, subjects_twinPick_MPD));  %%!!    %%!!  categorized
        GAAssess10_twinPick_Depression10_withMedu = cell2mat(GAAssess10_all(ismember(subjects_all, subjects_twinPick_Depression10_withMedu)));  %%!!    %%!!  
        GAAssess10_twinPick_Depression10_withMedu = GAAssess10_twinPick_Depression10_withMedu - mean(GAAssess10_twinPick_Depression10_withMedu);  %%!!    %%!!  centered
        C_twinPick_Depression10_withMedu = CC(ismember(subjects_twinPick_All, subjects_twinPick_Depression10_withMedu), :);  %%!!    %%!!  categorized/centered GAB+GAS+BW+Sex for subjects_twinPick_Depression10_withMedu  %%!!  %%!!  
        C_twinPick_Depression10_withMedu = [C_twinPick_Depression10_withMedu, Medu_twinPick_Depression10_withMedu, NDD_twinPick_Depression10_withMedu, MPD_twinPick_Depression10_withMedu, GAAssess10_twinPick_Depression10_withMedu];  %%!!    %%!!  All covs for longitudinal regression test (except for intercept 1+)
        Depression10_twinPick_Depression10_withMedu = Depression10_all(ismember(subjects_all, subjects_twinPick_Depression10_withMedu));  %%!!    %%!!  no need to center
        measures_feature_twinPick_Depression10_withMedu = measures_feature(ismember(subjects_twinPick_All, subjects_twinPick_Depression10_withMedu), :);  %%!!  
        X = measures_feature_twinPick_Depression10_withMedu;  %%!!  
        Y = Depression10_twinPick_Depression10_withMedu;  %%!!  
        C = C_twinPick_Depression10_withMedu;  %%!!  
        outdir = [outputpath 'Depression10_' level '_' measure label Cov_label '_' group '/data/'];  %%!!  %%!!  
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
    labelsX = names_funPar';  %%!!  %%!!  
    for xx = 1:size(X, 2)
        labelX = labelsX{xx};  %%!!  
        L{1 + xx, 1} = labelX; %% 
        L{1 + xx, 2} = measure; %% network  %%!!  
        L{1 + xx, 3} = labelX; %% 
        L{1 + xx, 4} = labelX; %% 
    end
    T = array2table(L); %% 
    writetable(T, [outputpath 'LabelsX_' level '_' measure label Cov_label '.csv'], 'WriteVariableNames', false);  %%!!  %%!!  
    
end


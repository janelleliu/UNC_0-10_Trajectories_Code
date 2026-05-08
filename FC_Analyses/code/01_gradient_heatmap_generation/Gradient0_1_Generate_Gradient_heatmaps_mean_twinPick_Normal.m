clear
clc

addpath('/media/zhark2/glab1/Haitao/Toolbox_codes/NIfTI_20140122/');
mask_file = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-withCerebellum-4mm-mask.nii';
nii = load_nii(mask_file);  %%!!  
W_mask = nii.img;
voxelpar_file = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-4mm-mask-inds.nii.gz';  %%!!    %%!!  NEED CHANGE!
nii = load_nii(voxelpar_file);  %%!!  use this template!!!!    
W_voxelpar = nii.img;

%{
funpar_file = 'templates/infant-2yr-funPar-4mm.nii';
nii = load_nii(funpar_file);  %%!!  use this template!!!!    
W_funpar = nii.img;

W_funpar_masked = W_funpar .* int16(W_mask);
nii.img = W_funpar_masked;
funpar_masked_file = 'templates/infant-2yr-funPar-4mm_masked.nii.gz';  %%!!  
save_nii(nii, funpar_masked_file);  %%!!  
%}

measures = {'Gradient1', 'Gradient2', 'Gradient3', 'Gradient1_AlignedToHCP', 'Gradient2_AlignedToHCP', 'Gradient3_AlignedToHCP'};  %%!!  %%!!  

for mm=1:length(measures)
    
measure = measures{mm};
%datapath = 'FC_Matrices/';  %%!!    %%!!  NEED CHANGE!
outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Gradient0_Gradients_results_ref_dm/Gradients_results_AlignedToHCP/'];  %%!!    %%!!  NEED CHANGE!  %%!!    %%!!  _ref_dm
if ~exist(outputpath, 'dir')
    mkdir(outputpath);
end
%listpath = '/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists_0.3mm/';  %%!!  
%tr = 90;  %%!!  just for path namings    
num_voxelpar = max(W_voxelpar(:));  %%!!  2yr voxelpar    
%ages = {'neonate', 'oneyear', 'twoyear'};
ages = {'HCP', 'neonate_twinPick_32W_Healthy', 'oneyear_twinPick_32W_Healthy', 'twoyear_twinPick_32W_Healthy', 'fouryear_twinPick_32W_Healthy', 'sixyear_twinPick_32W_Healthy', 'eightyear_twinPick_32W_Healthy', 'tenyear_twinPick_32W_Healthy'};  %%!!    %%!!  
%ages_s = {'0', '1', '2', '4', '6', '8', '10'}; %%!!  
num_a = length(ages);

%HCP_M_mean = load([datapath 'HCP_mean_FC_M.1D']);
%HCP_M_mean(logical(eye(size(HCP_M_mean)))) = 4;  %%!!  

for aa = 1:num_a
    age = ages{aa};  %%!!  
    %age_s = ages_s{aa};  %%!!  
    %datadir = [datapath age '/']; %% 
    %outputdir = [outputpath age '/']; %% 
    %if ~exist(outputdir, 'dir')
    %    mkdir(outputdir);
    %end
    %subjects = importSubjIDs([listpath age_s '_full_subject_updated_final.txt']);  %%!!  _healthy  _Tra    %%!!  
    %num_s = length(subjects);
    %{
    parfor ss = 1:num_s
        subj = subjects{ss};
        infile = [datadir subj '_voxelpar_2yrspace_ROI_FC_Z_matrix.1D'];  %%!!  FC Z
        outfile = [outputdir subj '_' measure '_Heatmap_' age '.1D'];  %%!!  vector
        if ~exist(outfile, 'file') && exist(infile, 'file')
            Z_FC_matrix = load(infile);  %%!!  
            Z_FC_matrix(logical(eye(size(Z_FC_matrix)))) = 4;  %%!!  
            Mcorr = zeros(size(Z_FC_matrix,1), 1);
            for vv=1:size(Z_FC_matrix, 1)
                Mcorr(vv) = corr(Z_FC_matrix(:, vv), HCP_M_mean(:, vv));
            end
            McorrZ = atanh(Mcorr);  %%!!  
            dlmwrite(outfile, McorrZ, 'delimiter', '\t');  %%!!  
        end
    end
    %}
    %{
    for ss = 1:num_s
        subj = subjects{ss};
        outfile = [outputdir subj '_' measure '_Heatmap_' age '.1D'];  %%!!  vector %% got from HPC Rscripts  
        outfile1 = [outputdir subj '_' measure '_Heatmap_' age '.nii.gz'];  %%!!  map
        if ~exist(outfile1, 'file') && exist(outfile, 'file')
            GraphM = load(outfile);
            W = zeros(size(W_voxelpar), 'single');
            for vv=1:length(GraphM)
                W(W_voxelpar==vv) = GraphM(vv);
            end
            nii.img = W; %% 
            save_nii(nii, outfile1);
        end
    end
    %}
    
    outfile_mean = [outputpath age '_mean_FC_M_' measure '.1D'];  %%!!  vector  %%!!  NEED CHANGE!
    outfile_mean1 = [outputpath age '_mean_FC_M_' measure '.nii.gz'];  %%!!  map  %%!!  NEED CHANGE!
    %if ~exist(outfile_mean1, 'file')
        %{
        subjects = importSubjIDs([listpath age_s '_full_subject_updated_final_twinPick_32W_Healthy.txt']);  %%!!    %%!!  Normal  
        num_s = length(subjects);
        GraphM_mean = zeros(num_voxelpar, 1);
        for ss = 1:num_s
            subj = subjects{ss};
            outfile = [outputdir subj '_' measure '_Heatmap_' age '.1D'];  %%!!  vector
            GraphM = load(outfile);
            GraphM_mean = GraphM_mean + GraphM;
        end
        GraphM_mean = GraphM_mean / num_s; %% 
        dlmwrite(outfile_mean, GraphM_mean, 'delimiter', '\t');  %%!!  
        %}
        MeasureM_mean = load(outfile_mean);  %%!!  
        W = zeros(size(W_voxelpar), 'single');
        for vv=1:length(MeasureM_mean)
            W(W_voxelpar==vv) = MeasureM_mean(vv);
        end
        nii.img = W; %% 
        save_nii(nii, outfile_mean1);
    %end
    
end

end


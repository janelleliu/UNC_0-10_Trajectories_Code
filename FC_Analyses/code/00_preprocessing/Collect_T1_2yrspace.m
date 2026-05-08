clear
clc

ages_s = {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear'};
%ages_s = {'neonate'};
n_a = length(ages_s);
ages_ss = {'0', '1', '2', '4', '6', '8', '10'};
%ages_ss = {'0'};

for aa=1:n_a
    age_s = ages_s{aa};
    age_ss = ages_ss{aa};
    
    if ismember(age_s, {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear'})
        FD = 0.3;  %%!!(1st) 
        datapath = ['/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/PreProResults_' num2str(FD) 'mm/' age_s '/'];
        outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/T1s_2yrspace/' age_s '/'];
        if ~exist(outputpath,'dir')
            mkdir(outputpath); 
        end
        subjects = importSubjIDs(['/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists_0.3mm/' age_ss '_full_subject_updated_final_twinPick.txt']);  %%!!  
        num_subj = length(subjects);
        parfor s = 1:num_subj 
            subj = subjects{s};
            infile = [datapath subj '/PreProc/pa02_' subj '_T1_a2s_ANTsWarped_2yrspace.nii.gz'];
            outfile = [outputpath 'pa02_' subj '_T1_a2s_ANTsWarped_2yrspace.nii.gz'];  %%!!  
            % copyfile
            if exist(infile, 'file') && ~exist(outfile, 'file') 
                copyfile(infile, outfile);
            end
        end
    elseif ismember(age_s, {'eightyear', 'tenyear'})
        labels = {'old', 'new'};
        for ll = 1:length(labels)
            label = labels{ll};
            FD = 0.3;  %%!!(1st) 
            datapath = ['/media/zhark2/glab8/Haitao/UNC_8_10/PreProResults_' num2str(FD) 'mm/' label '_protocol/' age_s '/'];
            outputpath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/T1s_2yrspace/' age_s '/'];
            if ~exist(outputpath,'dir')
                mkdir(outputpath); 
            end
            subjects = importSubjIDs(['/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists_0.3mm/' age_ss '_full_subject_updated_final_twinPick.txt']);  %%!!  
            num_subj = length(subjects);
            parfor s = 1:num_subj 
                subj = subjects{s};
                infile = [datapath subj '/PreProc/pa02_' subj '_T1_a2s_ANTsWarped_2yrspace.nii.gz'];
                outfile = [outputpath 'pa02_' subj '_T1_a2s_ANTsWarped_2yrspace.nii.gz'];  %%!!  
                % copyfile
                if exist(infile, 'file') && ~exist(outfile, 'file') 
                    copyfile(infile, outfile);
                end
            end
        end
    end
    
end


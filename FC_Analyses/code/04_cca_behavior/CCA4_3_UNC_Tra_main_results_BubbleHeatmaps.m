clear
clc

test_str = '0';  %%!!  %%!!  '0' means rest of twinPick as test, '1' means Additional Twin as test, '2' means rest of all (0+1) as test  %%!!  %%!!  

perm_label = '_permtrain_correlsimwxy';  %%!!  %%!!  

set(groot, 'defaultTextInterpreter', 'none');  %%!!  %%!!  enable '_'
set(0, 'defaultAxesTickLabelInterpreter', 'none');  %%!!  %%!!  enable '_'

datapath = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/CCA4_M_FC_Z_All_for_CCA_Ages/';  %%!!  _AddTwin
outputpath = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/CCA4_M_FC_Z_All_for_CCA_Ages/0BubbleHeatmaps/';  %%!!  _AddTwin
if ~exist(outputpath, 'dir')
    mkdir(outputpath);
end

measures_YR = {'4', '6', '8', '10'};  %%!!  {'4', '6', '8', '10'} for IQ/ANX/DEP, {'1', '2'} for Mul
for YY = 1:length(measures_YR)
    measure_YR = measures_YR{YY};

ages = {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear'};  %%!!  
ages_num = [0, 1, 2, 4, 6, 8, 10];  %%!!  
ages_s = {'0YR', '1YR', '2YR', '4YR', '6YR', '8YR', '10YR'};  %%!!  
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
        % plot a 5/4/2Behavior*7Age Bubble Heatmap (of mean testing Corr M) for each level_measure
        M = zeros(length(Ys_label), length(ages));  %%!!  mean testing Corr M
        Sw = zeros(length(Ys_label), length(ages));  %%!!  mean X weight similarity Sw
        Sl = zeros(length(Ys_label), length(ages));  %%!!  mean X loading similarity Sl
        H = zeros(length(Ys_label), length(ages));  %%!!  significance H
        Pmin = zeros(length(Ys_label), length(ages));  %%!!  min P
        for aa = 1:length(ages)  %%!!  
            age = ages{aa};
            age_num = ages_num(aa);
            for yy = 1:length(Ys_label)
                Y_label = Ys_label{yy};
                datadir = [datapath Y_label '_' level '_' measure '_' age '/framework/cca_pca_holdout1-' test_str '.00_subsamp5-0.20_nperm1000' perm_label '/res/level1/'];  %%!!  %%!!  Normal twinPick as training, different tests
                load([datadir 'model_1.mat']); %% correl, simwx, trcorrel, etc.
                load([datadir 'res_1.mat']); %% res
                M(yy, aa) = mean(correl);  %%!!  mean testing Corr M
                Sw(yy, aa) = mean(simwx(:));  %%!!  mean X weight similarity Sw
                load([datadir 'Loadings_align.mat']); %% simlx_mean
                Sl(yy, aa) = simlx_mean;  %%!!  mean X loading similarity Sl
                if res.stat.sig && M(yy, aa)>=0.2  %%!!  %%!!  Sw(yy, aa)>=0.5  %%!!  %%!!   && Sl(yy, aa)>=0.6
                    H(yy, aa) = 1;
                    infolder = [datapath Y_label '_' level '_' measure '_' age];  %%!!  
                    outfolder = [datapath '0Significance_trainperm_correlsimwxy_new/' Y_label '_' level '_' measure '_' age];  %%!!  %%!!  
                    if ~exist(outfolder, 'dir')  %%!!  
                        mkdir(outfolder);  %%!!  
                    end  %%!!  
                    copyfile(infolder, outfolder);  %%!!  %%!!  
                end
                Pmin(yy, aa) = min(res.stat.pval);  %%!!  min P
            end
        end
        save([outputpath 'BubbleHeatmap_OneTestCorrM_Test' test_str '_' level '_' measure perm_label '_ACYR' measure_YR '.mat'], 'M', 'Sw', 'Sl', 'H', 'Pmin', 'Ys_label', 'ages', 'ages_s', 'level', 'measure', 'measure_YR');  %%!!  %%!!  Mean / One  
        
        %{
        % bubblechart is only in Matlab2020, use the saved M and plot locally
        M(M<0) = 0;  %%!!  %%!!  CCA should > 0
        [x,y] = meshgrid(1:size(M,1), 1:size(M,2)); 
        bubblechart(x(:),y(:),abs(M(:)),M(:))
        % Cosmetics
        %colormap('jet')
        grid on
        set(gca,'xtick', 1:size(M,2), ...  %%??  
            'ytick', 1:size(M,1), ...  %%??  
            'YDir', 'Reverse'); % typically corr matrices use flipped y axes
        %xlabel('x index')
        %ylabel('y index')
        xticks(1:length(Ys_label));  %%!!  
        xticklabels(Ys_label);  %%!!  
        yticks(1:length(ages));  %%!!  
        yticklabels(ages_s);  %%!!  
        title([level '_' measure]);  %%!!  
        cb = colorbar; 
        ylabel(cb, 'Mean Test Corr')  %%!!  
        caxis([0,0.5])  %%!!  
        saveas(gcf, [outputpath 'BubbleHeatmap_MeanTestCorrM_' level '_' measure '.png']);  %%!!  
        close;
        %}
        
    end
end

end


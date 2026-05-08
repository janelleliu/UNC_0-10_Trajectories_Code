clear
clc

%addpath('/media/zhark2/glab1/Haitao/Toolbox_codes/NIfTI_20140122/'); 
%addpath('/media/zhark2/glab1/Haitao/Toolbox_codes/github_repo_myversion/');  %%!!  

%ROIs = {'visualOne','visualTwo','visualThree','DMN','sensoryMotor','auditory','executiveControl','frontoParietalOne','frontoParietalTwo', 'anteriorinsulaR', 'amygdala', 'hippocampus'};  %% 12    %%!!  (omit cerebellum)
%num_ROIs = length(ROIs);

ROIs = {'Visual', 'Somatomotor', 'Dorsal-A', 'Ventral-A', 'Limbic', 'Frontoparietal', 'Default', 'Subcortical'};  %% 8    %%!!  %%!!  Yeo 8 networks (Ventral Attention is Salience)
networks = {'VIS', 'SMN', 'DAN', 'SAL', 'LIM', 'FPN', 'DMN', 'SUB'};  %% 8    %%!!  updated!!  
num_ROIs = length(ROIs); % 

Colors = [120 18 134; 70 130 180; 0 118 14; 196 58 250; 206 220 46; 230 148 34; 205 62 78; 128 128 128] / 255;  %%!!  RGB values for Yeo 8 networks  (220 248 164) Changed Limbic!!  

measures = {'Str', 'Enodal', 'Elocal', 'McosSim2', 'Gradient1_AlignedToHCP', 'Gradient2_AlignedToHCP', 'GradientsDispN', 'GradientsDispN2'};  %%!!    %%!!  
measures_str = {'Str', 'Enodal', 'Elocal', 'McosSim', 'Gradient1', 'Gradient2', 'Dispersion', 'Dispersion-Normalized'};  %%!!    %%!!  
Cov_label = '_Harmo';  %%!!    %%!!  ''(original) / '_Harmo'  %%!!    %%!!  
if strcmp(Cov_label, '')
    ylims = [0,200; 0.15,0.35; 0.2,0.45; 0.15,0.55; -3,3; -3,3; 1,2; 0.0045,0.0075];  %%!!    %%!!  
elseif strcmp(Cov_label, '_Harmo')
    ylims = [50,200; 0.25,0.35; 0.3,0.5; 0.15,0.6; -3,3; -3,3; 1,2; 0.0045,0.0075];  %%!!    %%!!  
end

% UNC: UNC 0 1 2 4 6 8 10 in 2yr space
dataset = 'UNC';
FD = '_0.3mm'; %% 0.3mm:'_0.3mm' or 0.5mm:'_0.5mm' 
threshold = 90;  %%  notr90 

for mm=7:8%1:length(measures)  %%!!    %%!!  7:8%
    measure = measures{mm};
    measure_str = measures_str{mm};  %%!!  

if ismember(measure, {'Str', 'BC', 'Enodal', 'Elocal'})  %%!!  %%!!  graph measures
    label = '_8mm2';  %%!!    %%!!  _8mm2
else
    label = '';  %%!!  
end

groups = {'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear'};  %%!!  , 'HCP_2yrspace_4mm'
groups_s = {'0', '1', '2', '4', '6', '8', '10'};  %%!!  , 'HCP_2yrspace_4mm'
GAS_rough = [300, 665, 1030, 1760, 2490, 3220, 3950];  %%!!  , 4680
GAS_rough_labels = {'300', '665', '1030', '1760', '2490', '3220', '3950'};  %%!!  , 'Adult'

datapath = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/MSFPCA3_New_tables_results/mFPCA/GitHub_mFPCA_updated/UNC_tra_mfpca_analyses_' measure label Cov_label '_twinPick_All/notebooks/'];  %%!!  %%!!  
%datapath0 = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/MSFPCA3_New_tables_results/M_FC_Z_' measure label Cov_label '_twinPick_All/'];  %%!!  %%!!  same
outputpath = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/MSFPCA3_New_tables_results/mFPCA/mfpca_plot_results_Reconstruct/';  %%!!  
if ~exist(outputpath, 'dir')  %%!!  
    mkdir(outputpath);  %%!!  
end
listpath = ['/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists_0.3mm/'];
subjects_twinPick_All = importSubjIDs([listpath '01246810_Union_full_subject_updated_final_twinPick.txt']);
subjects_twinPick_Normal = importSubjIDs([listpath '01246810_Union_full_subject_updated_final_twinPick_32W_Healthy.txt']);
subjects_twinPick_NDD = importSubjIDs([listpath '01246810_Union_full_subject_updated_final_twinPick_ADAU.txt']);
subjects_twinPick_MPD = importSubjIDs([listpath '01246810_Union_full_subject_updated_final_twinPick_MaternalPD.txt']);

FPC_scores = readcell([datapath 'mfpca_tra_' measure label Cov_label '_twinPick_All_FPC_scores_1.csv'], 'DatetimeType', 'text');  %%!!    %%!!  
X_GAS_Day_Y_STDZ_Mean_mFPCA = readcell([datapath 'mfpca_tra_' measure label Cov_label '_twinPick_All_X_GAS_Day_Y_STDZ_Mean_mFPCA_1.csv']);  %%!!  
X_GAS_Day_Y_STDZ_FPCs_mFPCA = readcell([datapath 'mfpca_tra_' measure label Cov_label '_twinPick_All_X_GAS_Day_Y_STDZ_FPCs_mFPCA_1.csv']);  %%!!  
Original_Scale_Var_mean = readcell([datapath 'mfpca_tra_' measure label Cov_label '_twinPick_All_Original_Scale_Var_mean_1.csv']);  %%!!  
Original_Scale_Var_std = readcell([datapath 'mfpca_tra_' measure label Cov_label '_twinPick_All_Original_Scale_Var_std_1.csv']);  %%!!  

FPC_scores_twinPick_All = cell2mat(FPC_scores(2:end, 4:end));  %%!!  
FPC_scores_twinPick_Normal = cell2mat(FPC_scores(ismember(FPC_scores(:, 2), subjects_twinPick_Normal), 4:end));  %%!!  
FPC_scores_twinPick_NDD = cell2mat(FPC_scores(ismember(FPC_scores(:, 2), subjects_twinPick_NDD), 4:end));  %%!!  
FPC_scores_twinPick_MPD = cell2mat(FPC_scores(ismember(FPC_scores(:, 2), subjects_twinPick_MPD), 4:end));  %%!!  
X_GAS_Day = cell2mat(X_GAS_Day_Y_STDZ_Mean_mFPCA(2:end, 1));  %%!!  
Y_STDZ_Mean_mFPCA = cell2mat(X_GAS_Day_Y_STDZ_Mean_mFPCA(2:end, 2:end));  %%!!  
Y_STDZ_FPCs_mFPCA = cell2mat(X_GAS_Day_Y_STDZ_FPCs_mFPCA(2:end, 2:end));  %%!!  
Var_mean = cell2mat(Original_Scale_Var_mean(2:end, 2:end));  %%!!  
Var_std = cell2mat(Original_Scale_Var_std(2:end, 2:end));  %%!!  
n_FPC = size(Y_STDZ_FPCs_mFPCA, 2) / num_ROIs;
n_T = size(Y_STDZ_Mean_mFPCA, 1);

Individual_Curves_twinPick_All = zeros(length(subjects_twinPick_All), n_T, num_ROIs);
for ii = 1:length(subjects_twinPick_All)
    for pp = 1:num_ROIs
        Individual_Curve = Y_STDZ_Mean_mFPCA(:, pp);
        for kk = 1:n_FPC
            Individual_Curve = Individual_Curve + Y_STDZ_FPCs_mFPCA(:, (pp-1)*n_FPC+kk)*FPC_scores_twinPick_All(ii, (pp-1)*n_FPC+kk);
        end
        Individual_Curve = Individual_Curve * Var_std(pp) + Var_mean(pp);  %%!!  Re-scale
        Individual_Curves_twinPick_All(ii, :, pp) = Individual_Curve;  %%!!  
    end
end
Individual_Curves_Mean_twinPick_All = squeeze(mean(Individual_Curves_twinPick_All, 1));
Individual_Curves_Std_twinPick_All = squeeze(std(Individual_Curves_twinPick_All, 0, 1));  %%!!  

Individual_Curves_twinPick_Normal = zeros(length(subjects_twinPick_Normal), n_T, num_ROIs);
for ii = 1:length(subjects_twinPick_Normal)
    for pp = 1:num_ROIs
        Individual_Curve = Y_STDZ_Mean_mFPCA(:, pp);
        for kk = 1:n_FPC
            Individual_Curve = Individual_Curve + Y_STDZ_FPCs_mFPCA(:, (pp-1)*n_FPC+kk)*FPC_scores_twinPick_Normal(ii, (pp-1)*n_FPC+kk);
        end
        Individual_Curve = Individual_Curve * Var_std(pp) + Var_mean(pp);  %%!!  Re-scale
        Individual_Curves_twinPick_Normal(ii, :, pp) = Individual_Curve;  %%!!  
    end
end
Individual_Curves_Mean_twinPick_Normal = squeeze(mean(Individual_Curves_twinPick_Normal, 1));
Individual_Curves_Std_twinPick_Normal = squeeze(std(Individual_Curves_twinPick_Normal, 0, 1));  %%!!  

Individual_Curves_twinPick_NDD = zeros(length(subjects_twinPick_NDD), n_T, num_ROIs);
for ii = 1:length(subjects_twinPick_NDD)
    for pp = 1:num_ROIs
        Individual_Curve = Y_STDZ_Mean_mFPCA(:, pp);
        for kk = 1:n_FPC
            Individual_Curve = Individual_Curve + Y_STDZ_FPCs_mFPCA(:, (pp-1)*n_FPC+kk)*FPC_scores_twinPick_NDD(ii, (pp-1)*n_FPC+kk);
        end
        Individual_Curve = Individual_Curve * Var_std(pp) + Var_mean(pp);  %%!!  Re-scale
        Individual_Curves_twinPick_NDD(ii, :, pp) = Individual_Curve;  %%!!  
    end
end
Individual_Curves_Mean_twinPick_NDD = squeeze(mean(Individual_Curves_twinPick_NDD, 1));
Individual_Curves_Std_twinPick_NDD = squeeze(std(Individual_Curves_twinPick_NDD, 0, 1));  %%!!  

Individual_Curves_twinPick_MPD = zeros(length(subjects_twinPick_MPD), n_T, num_ROIs);
for ii = 1:length(subjects_twinPick_MPD)
    for pp = 1:num_ROIs
        Individual_Curve = Y_STDZ_Mean_mFPCA(:, pp);
        for kk = 1:n_FPC
            Individual_Curve = Individual_Curve + Y_STDZ_FPCs_mFPCA(:, (pp-1)*n_FPC+kk)*FPC_scores_twinPick_MPD(ii, (pp-1)*n_FPC+kk);
        end
        Individual_Curve = Individual_Curve * Var_std(pp) + Var_mean(pp);  %%!!  Re-scale
        Individual_Curves_twinPick_MPD(ii, :, pp) = Individual_Curve;  %%!!  
    end
end
Individual_Curves_Mean_twinPick_MPD = squeeze(mean(Individual_Curves_twinPick_MPD, 1));
Individual_Curves_Std_twinPick_MPD = squeeze(std(Individual_Curves_twinPick_MPD, 0, 1));  %%!!  

%X_GAS_Day_Y_Mean_mFPCA = readcell([datapath 'mfpca_tra_' measure label '_twinPick_All_X_GAS_Day_Y_Mean_mFPCA_1.csv']);  %%!!  
%X_GAS_Day = cell2mat(X_GAS_Day_Y_Mean_mFPCA(2:end, 1));  %%!!  
%Y_Mean_mFPCA = cell2mat(X_GAS_Day_Y_Mean_mFPCA(2:end, 2:end));  %%!!  
%{
if ~ismember(measure, {'PeakFre1', 'RMSSD'})  %%!!  not temporal measures
    group = groups{end};
    group_s = groups_s{end};
    load([datapath0 'M_FC_Z_' measure label FD '_notr' num2str(threshold) '_' dataset '_' group '.mat']);  %%!!  same
    measure_mean = mean(M_FC_Z, 1); %% HCP Adult
end
%}
linewidth = 2;  %%!!  %%!!  
facealpha = 0.3;  %%!!  %%!!  

figure;
hold on; %% 
X_inds = X_GAS_Day>=300 & X_GAS_Day<=3950;  %%!!  
x = X_GAS_Day(X_inds); %% 
y = Individual_Curves_Mean_twinPick_All(X_inds, :);  %%!!    %%!!  
for rr = 1:num_ROIs
    plot(x, y(:, rr), 'Color', Colors(rr, :), 'LineStyle', '-', 'LineWidth', linewidth);  %%    %%!!  'Marker', 'o', 
end
%plot(x, y(:, 9), 'Color', Colors(9, :), 'LineStyle', '-', 'LineWidth', linewidth);  %%    %%!!  'Marker', '*', 
%plot(x, y(:, 10), 'Color', Colors(10, :), 'LineStyle', '-', 'LineWidth', linewidth);  %%    %%!!  'Marker', '*', 
legend(networks, 'Location', 'northeastoutside'); %% 

std_dev = Individual_Curves_Std_twinPick_All(X_inds, :);  %%!!    %%!!  
sem = std_dev / sqrt(length(subjects_twinPick_All));  %%!!  standard error mean
upper_bound = y + sem;  %%!!  
lower_bound = y - sem;  %%!!  
for rr = 1:num_ROIs
    fill([x; flipud(x)], [upper_bound(:, rr); flipud(lower_bound(:, rr))], Colors(rr, :), 'FaceAlpha', facealpha, 'EdgeColor', 'none', 'HandleVisibility', 'off');  %%!!    %%!!  
end

%{
if ~ismember(measure, {'PeakFre1', 'RMSSD'})  %%!!  not temporal measures
    x = [3950, 4680]'; %%   %%!!  
    y = [y(end, :); measure_mean];  %%!!  
    plot(x, y(:, 1), 'Color', Colors(1, :), 'LineStyle', '--', 'LineWidth', linewidth, 'HandleVisibility', 'off');  %%    %%!!  'Marker', 'o', 
    plot(x, y(:, 2), 'Color', Colors(2, :), 'LineStyle', '--', 'LineWidth', linewidth, 'HandleVisibility', 'off');  %%    %%!!  'Marker', 'o', 
    plot(x, y(:, 3), 'Color', Colors(3, :), 'LineStyle', '--', 'LineWidth', linewidth, 'HandleVisibility', 'off');  %%    %%!!  'Marker', 'o', 
    plot(x, y(:, 4), 'Color', Colors(4, :), 'LineStyle', '--', 'LineWidth', linewidth, 'HandleVisibility', 'off');  %%    %%!!  'Marker', 'o', 
    plot(x, y(:, 5), 'Color', Colors(5, :), 'LineStyle', '--', 'LineWidth', linewidth, 'HandleVisibility', 'off');  %%    %%!!  'Marker', '+', 
    plot(x, y(:, 6), 'Color', Colors(6, :), 'LineStyle', '--', 'LineWidth', linewidth, 'HandleVisibility', 'off');  %%    %%!!  'Marker', '+', 
    plot(x, y(:, 7), 'Color', Colors(7, :), 'LineStyle', '--', 'LineWidth', linewidth, 'HandleVisibility', 'off');  %%    %%!!  'Marker', '*', 
    plot(x, y(:, 8), 'Color', Colors(8, :), 'LineStyle', '--', 'LineWidth', linewidth, 'HandleVisibility', 'off');  %%    %%!!  'Marker', '*', 
    %plot(x, y(:, 9), 'Color', Colors(9, :), 'LineStyle', '--', 'LineWidth', linewidth, 'HandleVisibility', 'off');  %%    %%!!  'Marker', '*', 
    %plot(x, y(:, 10), 'Color', Colors(10, :), 'LineStyle', '--', 'LineWidth', linewidth, 'HandleVisibility', 'off');  %%    %%!!  'Marker', '*', 
end
%}
hold off; %% 
xlim([300, 3950]);  %%!!  4680
ylim(ylims(mm,:));  %%!!  %%!!  
xticks(GAS_rough);  %%!!  
xticklabels(GAS_rough_labels);  %%!!  
%yticks([-0.2:0.1:1.0]);  %%!!  
xlabel('GAS Day');
ylabel(['Mean mFPCA ' measure_str ' twinPick All']);  %%!!  label Cov_label 
set(gcf, 'position', [500, 500, 1000, 800]);  %%!!    %%!!  [500, 500, 1200, 800]
set(gca, 'fontsize', 20);  %%!!  
if strcmp(measure, 'Gradient2_AlignedToHCP')
    set(gca, 'YDir', 'reverse');  %%!!  reverse Transmodal-to-Primary to Primary-to-Transmodal
end
%outfile = [outputpath 'Mean_mFPCA_' measure label Cov_label '_twinPick_All_Plot_updated_Original' FD '_notr' num2str(threshold) '_' dataset '.fig']; %%   %%!!  
%saveas(gcf, outfile);  %%!!  
outfile0 = [outputpath 'Mean_mFPCA_' measure label Cov_label '_twinPick_All_Plot_updated_Original' FD '_notr' num2str(threshold) '_' dataset '.png']; %%   %%!!  
saveas(gcf, outfile0);  %%!!  
clf(gcf);
close(gcf);
%outfile1 = [outputpath 'Mean_mFPCA_' measure label Cov_label '_twinPick_All_M_Original' FD '_notr' num2str(threshold) '_' dataset '.mat']; %%   %%!!  
%save(outfile1, 'ROIs', 'networks', 'groups', 'groups_s', 'GAS_rough', 'X_GAS_Day_Y_Mean_mFPCA', 'X_GAS_Day', 'Y_Mean_mFPCA', 'Colors');  %%!!  %%!!  

figure;
hold on; %% 
X_inds = X_GAS_Day>=300 & X_GAS_Day<=3950;  %%!!  
x = X_GAS_Day(X_inds); %% 
y = Individual_Curves_Mean_twinPick_Normal(X_inds, :);  %%!!    %%!!  
for rr = 1:num_ROIs
    plot(x, y(:, rr), 'Color', Colors(rr, :), 'LineStyle', '-', 'LineWidth', linewidth);  %%    %%!!  'Marker', 'o', 
end
legend(networks, 'Location', 'northeastoutside'); %% 
std_dev = Individual_Curves_Std_twinPick_Normal(X_inds, :);  %%!!    %%!!  
sem = std_dev / sqrt(length(subjects_twinPick_Normal));  %%!!  standard error mean
upper_bound = y + sem;  %%!!  
lower_bound = y - sem;  %%!!  
for rr = 1:num_ROIs
    fill([x; flipud(x)], [upper_bound(:, rr); flipud(lower_bound(:, rr))], Colors(rr, :), 'FaceAlpha', facealpha, 'EdgeColor', 'none', 'HandleVisibility', 'off');  %%!!    %%!!  
end
hold off; %% 
xlim([300, 3950]);  %%!!  4680
ylim(ylims(mm,:));  %%!!  %%!!  
xticks(GAS_rough);  %%!!  
xticklabels(GAS_rough_labels);  %%!!  
%yticks([-0.2:0.1:1.0]);  %%!!  
xlabel('GAS Day');
ylabel(['Mean mFPCA ' measure_str ' twinPick Normal']);  %%!!  label Cov_label 
set(gcf, 'position', [500, 500, 1000, 800]);  %%!!    %%!!  [500, 500, 1200, 800]
set(gca, 'fontsize', 20);  %%!!  
if strcmp(measure, 'Gradient2_AlignedToHCP')
    set(gca, 'YDir', 'reverse');  %%!!  reverse Transmodal-to-Primary to Primary-to-Transmodal
end
%outfile = [outputpath 'Mean_mFPCA_' measure label Cov_label '_twinPick_Normal_Plot_updated_Original' FD '_notr' num2str(threshold) '_' dataset '.fig']; %%   %%!!  
%saveas(gcf, outfile);  %%!!  
outfile0 = [outputpath 'Mean_mFPCA_' measure label Cov_label '_twinPick_Normal_Plot_updated_Original' FD '_notr' num2str(threshold) '_' dataset '.png']; %%   %%!!  
saveas(gcf, outfile0);  %%!!  
clf(gcf);
close(gcf);

figure;
hold on; %% 
X_inds = X_GAS_Day>=300 & X_GAS_Day<=3950;  %%!!  
x = X_GAS_Day(X_inds); %% 
y = Individual_Curves_Mean_twinPick_NDD(X_inds, :);  %%!!    %%!!  
for rr = 1:num_ROIs
    plot(x, y(:, rr), 'Color', Colors(rr, :), 'LineStyle', '-', 'LineWidth', linewidth);  %%    %%!!  'Marker', 'o', 
end
legend(networks, 'Location', 'northeastoutside'); %% 
std_dev = Individual_Curves_Std_twinPick_NDD(X_inds, :);  %%!!    %%!!  
sem = std_dev / sqrt(length(subjects_twinPick_NDD));  %%!!  standard error mean
upper_bound = y + sem;  %%!!  
lower_bound = y - sem;  %%!!  
for rr = 1:num_ROIs
    fill([x; flipud(x)], [upper_bound(:, rr); flipud(lower_bound(:, rr))], Colors(rr, :), 'FaceAlpha', facealpha, 'EdgeColor', 'none', 'HandleVisibility', 'off');  %%!!    %%!!  
end
hold off; %% 
xlim([300, 3950]);  %%!!  4680
ylim(ylims(mm,:));  %%!!  %%!!  
xticks(GAS_rough);  %%!!  
xticklabels(GAS_rough_labels);  %%!!  
%yticks([-0.2:0.1:1.0]);  %%!!  
xlabel('GAS Day');
ylabel(['Mean mFPCA ' measure_str ' twinPick NDD']);  %%!!  label Cov_label 
set(gcf, 'position', [500, 500, 1000, 800]);  %%!!    %%!!  [500, 500, 1200, 800]
set(gca, 'fontsize', 20);  %%!!  
if strcmp(measure, 'Gradient2_AlignedToHCP')
    set(gca, 'YDir', 'reverse');  %%!!  reverse Transmodal-to-Primary to Primary-to-Transmodal
end
%outfile = [outputpath 'Mean_mFPCA_' measure label Cov_label '_twinPick_NDD_Plot_updated_Original' FD '_notr' num2str(threshold) '_' dataset '.fig']; %%   %%!!  
%saveas(gcf, outfile);  %%!!  
outfile0 = [outputpath 'Mean_mFPCA_' measure label Cov_label '_twinPick_NDD_Plot_updated_Original' FD '_notr' num2str(threshold) '_' dataset '.png']; %%   %%!!  
saveas(gcf, outfile0);  %%!!  
clf(gcf);
close(gcf);

figure;
hold on; %% 
X_inds = X_GAS_Day>=300 & X_GAS_Day<=3950;  %%!!  
x = X_GAS_Day(X_inds); %% 
y = Individual_Curves_Mean_twinPick_MPD(X_inds, :);  %%!!    %%!!  
for rr = 1:num_ROIs
    plot(x, y(:, rr), 'Color', Colors(rr, :), 'LineStyle', '-', 'LineWidth', linewidth);  %%    %%!!  'Marker', 'o', 
end
legend(networks, 'Location', 'northeastoutside'); %% 
std_dev = Individual_Curves_Std_twinPick_MPD(X_inds, :);  %%!!    %%!!  
sem = std_dev / sqrt(length(subjects_twinPick_MPD));  %%!!  standard error mean
upper_bound = y + sem;  %%!!  
lower_bound = y - sem;  %%!!  
for rr = 1:num_ROIs
    fill([x; flipud(x)], [upper_bound(:, rr); flipud(lower_bound(:, rr))], Colors(rr, :), 'FaceAlpha', facealpha, 'EdgeColor', 'none', 'HandleVisibility', 'off');  %%!!    %%!!  
end
hold off; %% 
xlim([300, 3950]);  %%!!  4680
ylim(ylims(mm,:));  %%!!  %%!!  
xticks(GAS_rough);  %%!!  
xticklabels(GAS_rough_labels);  %%!!  
%yticks([-0.2:0.1:1.0]);  %%!!  
xlabel('GAS Day');
ylabel(['Mean mFPCA ' measure_str ' twinPick MPD']);  %%!!  label Cov_label 
set(gcf, 'position', [500, 500, 1000, 800]);  %%!!    %%!!  [500, 500, 1200, 800]
set(gca, 'fontsize', 20);  %%!!  
if strcmp(measure, 'Gradient2_AlignedToHCP')
    set(gca, 'YDir', 'reverse');  %%!!  reverse Transmodal-to-Primary to Primary-to-Transmodal
end
%outfile = [outputpath 'Mean_mFPCA_' measure label Cov_label '_twinPick_MPD_Plot_updated_Original' FD '_notr' num2str(threshold) '_' dataset '.fig']; %%   %%!!  
%saveas(gcf, outfile);  %%!!  
outfile0 = [outputpath 'Mean_mFPCA_' measure label Cov_label '_twinPick_MPD_Plot_updated_Original' FD '_notr' num2str(threshold) '_' dataset '.png']; %%   %%!!  
saveas(gcf, outfile0);  %%!!  
clf(gcf);
close(gcf);

figure;
hold on; %% 
X_inds = X_GAS_Day>=300 & X_GAS_Day<=3950;  %%!!  
x = X_GAS_Day(X_inds); %% 
y = Individual_Curves_Mean_twinPick_Normal(X_inds, :);  %%!!    %%!!  
for rr = 1:num_ROIs
    plot(x, y(:, rr), 'Color', Colors(rr, :), 'LineStyle', '-', 'LineWidth', linewidth);  %%    %%!!  'Marker', 'o', 
end
%legend(strcat('Normal-', networks), 'Location', 'northeastoutside'); %% 
std_dev = Individual_Curves_Std_twinPick_Normal(X_inds, :);  %%!!    %%!!  
sem = std_dev / sqrt(length(subjects_twinPick_Normal));  %%!!  standard error mean
upper_bound = y + sem;  %%!!  
lower_bound = y - sem;  %%!!  
for rr = 1:num_ROIs
    fill([x; flipud(x)], [upper_bound(:, rr); flipud(lower_bound(:, rr))], Colors(rr, :), 'FaceAlpha', facealpha, 'EdgeColor', 'none', 'HandleVisibility', 'off');  %%!!    %%!!  
end
y = Individual_Curves_Mean_twinPick_NDD(X_inds, :);  %%!!    %%!!  
for rr = 1:num_ROIs
    plot(x, y(:, rr), 'Color', Colors(rr, :), 'LineStyle', '--', 'LineWidth', linewidth);  %%    %%!!  'Marker', 'o', 
end
legend([strcat('Normal-', networks), strcat('NDD-', networks)], 'Location', 'northeastoutside'); %%   %%!!  
std_dev = Individual_Curves_Std_twinPick_NDD(X_inds, :);  %%!!    %%!!  
sem = std_dev / sqrt(length(subjects_twinPick_NDD));  %%!!  standard error mean
upper_bound = y + sem;  %%!!  
lower_bound = y - sem;  %%!!  
for rr = 1:num_ROIs
    fill([x; flipud(x)], [upper_bound(:, rr); flipud(lower_bound(:, rr))], Colors(rr, :), 'FaceAlpha', facealpha, 'EdgeColor', 'none', 'HandleVisibility', 'off');  %%!!    %%!!  
end
hold off; %% 
xlim([300, 3950]);  %%!!  4680
ylim(ylims(mm,:));  %%!!  %%!!  
xticks(GAS_rough);  %%!!  
xticklabels(GAS_rough_labels);  %%!!  
%yticks([-0.2:0.1:1.0]);  %%!!  
xlabel('GAS Day');
ylabel(['Mean mFPCA ' measure_str ' twinPick Normal-NDD']);  %%!!  label Cov_label 
set(gcf, 'position', [500, 500, 1000, 800]);  %%!!    %%!!  [500, 500, 1200, 800]
set(gca, 'fontsize', 20);  %%!!  
if strcmp(measure, 'Gradient2_AlignedToHCP')
    set(gca, 'YDir', 'reverse');  %%!!  reverse Transmodal-to-Primary to Primary-to-Transmodal
end
%outfile = [outputpath 'Mean_mFPCA_' measure label Cov_label '_twinPick_Normal_NDD_Plot_updated_Original' FD '_notr' num2str(threshold) '_' dataset '.fig']; %%   %%!!  
%saveas(gcf, outfile);  %%!!  
outfile0 = [outputpath 'Mean_mFPCA_' measure label Cov_label '_twinPick_Normal_NDD_Plot_updated_Original' FD '_notr' num2str(threshold) '_' dataset '.png']; %%   %%!!  
saveas(gcf, outfile0);  %%!!  
clf(gcf);
close(gcf);

figure;
hold on; %% 
X_inds = X_GAS_Day>=300 & X_GAS_Day<=3950;  %%!!  
x = X_GAS_Day(X_inds); %% 
y = Individual_Curves_Mean_twinPick_Normal(X_inds, :);  %%!!    %%!!  
for rr = 1:num_ROIs
    plot(x, y(:, rr), 'Color', Colors(rr, :), 'LineStyle', '-', 'LineWidth', linewidth);  %%    %%!!  'Marker', 'o', 
end
%legend(strcat('Normal-', networks), 'Location', 'northeastoutside'); %% 
std_dev = Individual_Curves_Std_twinPick_Normal(X_inds, :);  %%!!    %%!!  
sem = std_dev / sqrt(length(subjects_twinPick_Normal));  %%!!  standard error mean
upper_bound = y + sem;  %%!!  
lower_bound = y - sem;  %%!!  
for rr = 1:num_ROIs
    fill([x; flipud(x)], [upper_bound(:, rr); flipud(lower_bound(:, rr))], Colors(rr, :), 'FaceAlpha', facealpha, 'EdgeColor', 'none', 'HandleVisibility', 'off');  %%!!    %%!!  
end
y = Individual_Curves_Mean_twinPick_MPD(X_inds, :);  %%!!    %%!!  
for rr = 1:num_ROIs
    plot(x, y(:, rr), 'Color', Colors(rr, :), 'LineStyle', '--', 'LineWidth', linewidth);  %%    %%!!  'Marker', 'o', 
end
legend([strcat('Normal-', networks), strcat('MPD-', networks)], 'Location', 'northeastoutside'); %%   %%!!  
std_dev = Individual_Curves_Std_twinPick_MPD(X_inds, :);  %%!!    %%!!  
sem = std_dev / sqrt(length(subjects_twinPick_MPD));  %%!!  standard error mean
upper_bound = y + sem;  %%!!  
lower_bound = y - sem;  %%!!  
for rr = 1:num_ROIs
    fill([x; flipud(x)], [upper_bound(:, rr); flipud(lower_bound(:, rr))], Colors(rr, :), 'FaceAlpha', facealpha, 'EdgeColor', 'none', 'HandleVisibility', 'off');  %%!!    %%!!  
end
hold off; %% 
xlim([300, 3950]);  %%!!  4680
ylim(ylims(mm,:));  %%!!  %%!!  
xticks(GAS_rough);  %%!!  
xticklabels(GAS_rough_labels);  %%!!  
%yticks([-0.2:0.1:1.0]);  %%!!  
xlabel('GAS Day');
ylabel(['Mean mFPCA ' measure_str ' twinPick Normal-MPD']);  %%!!  label Cov_label 
set(gcf, 'position', [500, 500, 1000, 800]);  %%!!    %%!!  [500, 500, 1200, 800]
set(gca, 'fontsize', 20);  %%!!  
if strcmp(measure, 'Gradient2_AlignedToHCP')
    set(gca, 'YDir', 'reverse');  %%!!  reverse Transmodal-to-Primary to Primary-to-Transmodal
end
%outfile = [outputpath 'Mean_mFPCA_' measure label Cov_label '_twinPick_Normal_MPD_Plot_updated_Original' FD '_notr' num2str(threshold) '_' dataset '.fig']; %%   %%!!  
%saveas(gcf, outfile);  %%!!  
outfile0 = [outputpath 'Mean_mFPCA_' measure label Cov_label '_twinPick_Normal_MPD_Plot_updated_Original' FD '_notr' num2str(threshold) '_' dataset '.png']; %%   %%!!  
saveas(gcf, outfile0);  %%!!  
clf(gcf);
close(gcf);

end


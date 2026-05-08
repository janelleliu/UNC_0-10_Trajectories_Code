function CCA4_1_UNC_Tra_Pred(level, measure, age, age_num, Y_label)
% UNC_Tra_Pred
%
% # Syntax
%   UNC_Tra_Pred
%
%_______________________________________________________________________
% Copyright (C) 2022 University College London

% Written by Agoston Mihalik (cca-pls-toolkit@cs.ucl.ac.uk)
% $Id$

% This file is part of CCA/PLS Toolkit.
%
% CCA/PLS Toolkit is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% CCA/PLS Toolkit is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with CCA/PLS Toolkit. If not, see <https://www.gnu.org/licenses/>.

%----- Analysis

% Set path for analysis
set_path;

% Project folder
datapath = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/CCA4_M_FC_Z_All_for_CCA_Ages/';  %%!!  %%!!  %%!!  %%!!  _AddTwin
cfg.dir.project = [datapath Y_label '_' level '_' measure '_' age '/'];  %%!!  %%!!  

% Data settings
cfg.data.conf = 1;  %%!!    %%!!  Deconfounding!!!!    
cfg.data.preproc =  {'impute', 'zscore', 'deconf'};  %%!!    %%!!  Deconfounding!!!!    
cfg.data.X.deconf = 'standard';  %%!!  %%!!  
cfg.data.Y.deconf = 'standard';  %%!!  %%!!  

% Machine settings
%{
cfg.machine.name = 'rcca'; %% RCCA (won't work in this dataset, probably too many dimensions, and too few subjects)
cfg.machine.param.L2x = 0.1;  %%!!  fixed for the descriptive framework
cfg.machine.param.L2y = 0.1;  %%!!  fixed for the descriptive framework
%}
cfg.machine.name = 'cca'; %% (PCA-)CCA
cfg.machine.param.name = {'PCAx' 'PCAy'}; %% 
%cfg.machine.param.PCAx = 60;  %%!!  fixed for the descriptive framework  %%!!  NEED TO CHANGE!!!!  preditive: default linear(adapted in cfg_defaults.m) search: 1 to rank(X), n(10) times
if ismember(Y_label, {'AllBehavior4', 'AllBehavior6', 'AllBehavior8', 'AllBehavior10', 'AllCognition14', 'AllCognition16', 'AllCognition18', 'AllCognition110'})  %%!!  %%!!  
    cfg.machine.param.PCAy = 3;  %%!!  fixed for the descriptive/predictive framework: use all
elseif ismember(Y_label, {'AllEmotion4', 'AllEmotion6', 'AllEmotion8', 'AllEmotion10', 'AllCognition24', 'AllCognition26', 'AllCognition28', 'AllCognition210'})  %%!!  %%!!  
    cfg.machine.param.PCAy = 2;  %%!!  fixed for the descriptive/predictive framework: use all
elseif ismember(Y_label, {'MulSubs1', 'MulSubs2'})  %%!!  %%!!  5 Mullen Subscores
    cfg.machine.param.PCAy = 5;  %%!!  fixed for the descriptive/predictive framework: use all
else
    cfg.machine.param.PCAy = 1;  %%!!  fixed for the descriptive/predictive framework: use all
end
cfg.machine.param.nPCAx = 20;  %%!!  default search is 10  %%!!  
cfg.machine.param.rangePCAx = [10 70];  %%!!  %%!!  must define if nout = 1, otherwise propout(invalid) will be used to calculate defaults  %%!!  %%!!  

cfg.machine.metric = {'trcorrel' 'correl' 'simwx' 'simwy' ...
    'trexvarx' 'trexvary'};
cfg.machine.param.crit = 'correl+simwxy'; % out-of-sample corr  %%!!  %%!!  'correl+simwxy'!!  simwxy automatically averages non-NaN values  
cfg.machine.simw = 'correlation-Pearson';

% Framework settings
cfg.frwork.name = 'holdout'; %% 'permutation'
nperm = 1000; %% 1000 / 2000  %%!!  %%!!  
cfg.frwork.flag = ['_nperm' num2str(nperm) '_permtrain_correlsimwxy']; %% the predictive framework  %%!!  %%!!  only shuffle within training set in permutations!!!!  _correlsimwxy!!  
cfg.frwork.nlevel = 1; % only one mode (previously cause bugs in cfg_defaults.m line 162; FIXED)
cfg.frwork.split.nout = 1; % 5-fold training-testing outer split; 5 / 1(set Normal twinPick as training)
cfg.frwork.split.propout = 0; % 0.2 when nout != 1; 0 means rest of twinPick as test, 1 means Additional Twin as test, 2 means rest of all (0+1) as test  %%!!  %%!!  
cfg.frwork.split.nin = 5; % 5-fold training-validation inner split (within training, nested)
cfg.frwork.split.propin = 0.2;

% Deflation settings
cfg.defl.name = 'generalized';
%cfg.defl.crit = 'correl';  %%!!  %%!!  default, previously must state if include cfg.frwork.nlevel = 1 (seems a bug in toolkit cfg_defaults.m line 162; FIXED)

% Environment settings
cfg.env.comp = 'local';
cfg.env.verbose = 3;  %%!!  

% % Number of permutations
cfg.stat.nperm = nperm; %% 
cfg.stat.perm = 'train'; % 'train+test'(default)  %%!!  %%!!  only shuffle within training set in permutations!!!!

% Update cfg with defaults
cfg = cfg_defaults(cfg);

% Run analysis
main(cfg);

% Clean up analysis files to save disc space
cleanup_files(cfg);

%----- Visualization

% Set path for plotting
set_path('plot');

% Load res
res.dir.frwork = cfg.dir.frwork;
res.frwork.level = 1;
res.gen.selectfile = 'none';
res = res_defaults(res, 'load'); 

% align the signs of weights!!  
WeightX_raw = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['wX']);  %%!!  
WeightY_raw = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['wY']);  %%!!  
signs_align = ones(res.frwork.split.nall, 1);
for split = 1:res.frwork.split.nall
    signs_align(split) = sign(dot(WeightY_raw(res.frwork.split.best, :), WeightY_raw(split, :)));
end
[~, idx] = max(abs(WeightY_raw(res.frwork.split.best, :)));  %%!!  %%!!  
if WeightY_raw(res.frwork.split.best, idx) < 0 %% if max of abs Y weights in best-split are negative: flip it  %%!!  %%!!  
    signs_flip = -1;  %%!!  %%!!  
    label_flip = 1;  %%!!  %%!!  
else
    signs_flip = 1;  %%!!  %%!!  
    label_flip = 0;  %%!!  %%!!  
end
WeightX_align = signs_flip*signs_align.*WeightX_raw;  %%!!  %%!!  
WeightY_align = signs_flip*signs_align.*WeightY_raw;  %%!!  %%!!  
Weights_align{1} = WeightX_align;  %%!!  
Weights_align{2} = WeightY_align;  %%!!  

% Plot data projections
plot_proj(res, {'X' 'Y'}, res.frwork.level, 'osplit', ...
    res.frwork.split.best, 'training+test', '2d_group', ...  %%!!  %%!!  Previously bugs in misc/save_results.m; FIXED
    'gen.figure.ext', '.svg', ... %% 
    'gen.figure.Position', [0 0 500 400], ...
    'gen.axes.Position', [0.1798 0.1560 0.7252 0.7690], ...
    'gen.axes.XLim', [-0.6 0.6], 'gen.axes.YLim', [-0.6 0.6], ...  %%!!  
    'gen.axes.FontSize', 10, 'gen.legend.FontSize', 10, ...
    'gen.legend.Location', 'best', ...
    'proj.scatter.SizeData', 30, ...
    'proj.scatter.MarkerFaceColor', [0.3 0.3 0.9; 0.9 0.3 0.3], ...  %%!!  %%!!  
    'proj.scatter.MarkerEdgeColor', 'k', 'proj.lsline', 'on', 'proj.flip', label_flip, ...  %%!!  %%!!  
    'proj.xlabel', ['Brain latent variable ' level ' ' measure ' at ' num2str(age_num) 'YR'], ...  %%!!  
    'proj.ylabel', [Y_label ' latent variable']);
close;  %%!!  

%
% Plot brain weights as horizontal bar plot (already reversed xy-axis in plots)
plot_weight(res, 'X', 'behav', res.frwork.split.best, 'behav_horz', ... %%   %%!!  %%!!  
    'gen.figure.ext', '.svg', ... %% 
    'gen.axes.FontSize', 8, 'gen.legend.FontSize', 6, ...  %%!!  
    'gen.axes.XLim', [-1.2 1.2], 'gen.weight.flip', label_flip, ...  %%!!  %%!!  
    'behav.weight.sorttype', 'sign', 'behav.weight.numtop', 15, ...
    'behav.weight.norm', 'minmax', ... %% 
    'behav.ylabel', ['Brain FC variables ' level ' ' measure], ...  %%!!  %%!!  
    'behav.xlabel', 'Weight', ...  %%!!  %%!!  
    'behav.file.label', [datapath 'LabelsX_' level '_' measure '.csv']);  %%!!  %%!!  
close;  %%!!  

% Plot brain structure correlations as horizontal bar plot (already reversed xy-axis in plots)  
plot_weight(res, 'X', 'behav', res.frwork.split.best, 'behav_horz', ... %%   %%!!  %%!!  
    'gen.figure.ext', '.svg', ... %% 
    'gen.axes.FontSize', 8, 'gen.legend.FontSize', 6, ...  %%!!  
    'gen.axes.XLim', [-1 1], 'gen.weight.flip', label_flip, ...  %%!!  %%!!  
    'gen.weight.type', 'correlation', ...  %%!!    %%!!  Structure Correlation  
    'behav.weight.sorttype', 'sign', 'behav.weight.numtop', 15, ...
    'behav.weight.norm', 'none', ... %% minmax for weight  
    'behav.ylabel', ['Brain FC variables ' level ' ' measure], ...  %%!!  %%!!  
    'behav.xlabel', 'Structure Correlation', ...  %%!!    %%!!  Structure Correlation  
    'behav.file.label', [datapath 'LabelsX_' level '_' measure '.csv']);  %%!!  %%!!  
close;  %%!!  
%}

%if strcmp(Y_label, 'AllBehavior10')
    % Plot behavioral weights as vertical bar plot
    plot_weight(res, 'Y', 'behav', res.frwork.split.best, 'behav_vert', ... %%   %%!!  %%!!  
        'gen.figure.ext', '.svg', ... %% 
        'gen.axes.FontSize', 10, 'gen.legend.FontSize', 8, ...  %%!!  
        'gen.axes.YLim', [-1.2 1.2], 'gen.weight.flip', label_flip, ...  %%!!  %%!!  
        'behav.weight.sorttype', 'sign', 'behav.weight.numtop', 15, ...
        'behav.weight.norm', 'minmax', ... %% 
        'behav.xlabel', ['Behavioral variables'], ...  %%!!  %%!!  
        'behav.ylabel', 'Weight', ...  %%!!  %%!!  
        'behav.file.label', [datapath 'LabelsY_' Y_label '.csv']);  %%!!  %%!!  
    close;  %%!!  
%end

%if strcmp(Y_label, 'AllBehavior10')
    % Plot behavioral weights as vertical bar plot
    plot_weight(res, 'Y', 'behav', res.frwork.split.best, 'behav_vert', ... %%   %%!!  %%!!  
        'gen.figure.ext', '.svg', ... %% 
        'gen.axes.FontSize', 10, 'gen.legend.FontSize', 8, ...  %%!!  
        'gen.axes.YLim', [-1 1], 'gen.weight.flip', label_flip, ...  %%!!  %%!!  
        'gen.weight.type', 'correlation', ...  %%!!    %%!!  Structure Correlation  
        'behav.weight.sorttype', 'sign', 'behav.weight.numtop', 15, ...
        'behav.weight.norm', 'none', ... %% minmax for weight  
        'behav.xlabel', ['Behavioral variables'], ...  %%!!  %%!!  
        'behav.ylabel', 'Structure Correlation', ...  %%!!    %%!!  Structure Correlation  
        'behav.file.label', [datapath 'LabelsY_' Y_label '.csv']);  %%!!  %%!!  
    close;  %%!!  
%end

% Plot hyperparameter surface for grid search results
plot_paropt(res, res.frwork.split.best, {'trcorrel', 'correl', 'simwx'}, ...
    'gen.figure.Position', [500 600 1200 400], 'gen.axes.FontSize', 20, ...
    'gen.axes.XScale', 'linear', 'gen.axes.YScale', 'linear'); %% log log
close;  %%!!  


if strcmp(level, 'FC_Matrices')
    % plot the X weights (FC_Matrices)
    load('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/funpar_8Net_allinfo.mat');  %%!!  
    num_ROIs = 278;  %%!!  2yr funPar  
    %WeightX = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['wX']);  %%!!  
    weightX_best = WeightX_align(res.frwork.split.best, :);  %%!!  %%!!  
    M = zeros(num_ROIs, num_ROIs);
    M(triu(true(size(M)), 1)) = weightX_best;  %%!!  
    M = M + M';
    M_grouped = M(group_inds, group_inds);  %%!!  %%!!  
    imagesc(M_grouped); 
    colorbar;
    caxis([-1e-4 1e-4]); % Set the colorbar limits
    saveas(gcf, [res.dir.res '/weightX_M_grouped_best.png']);  %%!!  
    close(gcf);
    weightX_mean = mean(WeightX_align, 1);  %%!!  %%!!  
    M = zeros(num_ROIs, num_ROIs);
    M(triu(true(size(M)), 1)) = weightX_mean;  %%!!  
    M = M + M';
    M_grouped = M(group_inds, group_inds);  %%!!  %%!!  
    imagesc(M_grouped); 
    colorbar;
    caxis([-1e-4 1e-4]); % Set the colorbar limits
    saveas(gcf, [res.dir.res '/weightX_M_grouped_mean.png']);  %%!!  
    close(gcf);
end

if strcmp(level, 'ROIs')
    % save the ROI weights in .nii files
    maskfile = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-funPar-4mm-mask-inds.nii.gz']; % 2yr funPar 278 ROIs  %%!!  %%!!  
    nii = load_nii(maskfile);
    W_mask = nii.img;
    num_ROIs = 278;  %%!!  2yr funPar  
    %WeightX = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['wX']);  %%!!  
    weightX_best = WeightX_align(res.frwork.split.best, :);  %%!!  %%!!  
    W_best = zeros(size(W_mask), 'single');
    for rr=1:num_ROIs
        W_best(W_mask==rr) = weightX_best(rr);
    end
    nii.img = W_best;
    save_nii(nii, [res.dir.res '/weightX_W_best.nii.gz']);  %%!!  
    weightX_mean = mean(WeightX_align, 1);  %%!!  %%!!  
    W_mean = zeros(size(W_mask), 'single');
    for rr=1:num_ROIs
        W_mean(W_mask==rr) = weightX_mean(rr);
    end
    nii.img = W_mean;
    save_nii(nii, [res.dir.res '/weightX_W_mean.nii.gz']);  %%!!  
end

if strcmp(level, 'Networks')
    % plot the bar plots of Network weights
    ROIs = {'Visual', 'Somatomotor', 'Dorsal-A', 'Ventral-A', 'Limbic', 'Frontoparietal', 'Default', 'Subcortical'};  %% 8    %%!!  %%!!  Yeo 8 networks (Ventral Attention is Salience)
    networks = {'VIS', 'SMN', 'DAN', 'SAL', 'LIM', 'FPN', 'DMN', 'SUB'};  %% 8    %%!!  updated!!  
    num_ROIs = length(ROIs); % 
    Colors = [120 18 134; 70 130 180; 0 118 14; 196 58 250; 220 248 164; 230 148 34; 205 62 78; 128 128 128] / 255;  %%!!  RGB values for Yeo 8 networks  
    %WeightX = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['wX']);  %%!!  
    weightX_best = WeightX_align(res.frwork.split.best, :);  %%!!  %%!!  
    [~, rank_inds] = sort(weightX_best, 'descend');  %%!!  
    weightX_best_ranked = weightX_best(rank_inds);
    networks_ranked = networks(rank_inds);
    x = 1:num_ROIs;  %%!!  
    y = weightX_best_ranked;  %%!!  
    figure;  %%!!  
    hold on
    b = bar(x, y, 'FaceColor', 'flat');  %%!!  
    for i=1:length(x)
        b.CData(i,:) = Colors(rank_inds(i),:);  %%!!  
    end
    xticks(1:num_ROIs);  %%!!  
    xticklabels(networks_ranked);  %%!!  
    %ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['weightX best split']);  %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 15);  %%!!  
    hold off
    saveas(gcf, [res.dir.res '/weightX_barplot_best.png']);  %%!!  
    close; %% 
    weightX_mean = mean(WeightX_align, 1);  %%!!  %%!!  
    [~, rank_inds] = sort(weightX_mean, 'descend');  %%!!  
    weightX_mean_ranked = weightX_mean(rank_inds);
    networks_ranked = networks(rank_inds);
    x = 1:num_ROIs;  %%!!  
    y = weightX_mean_ranked;  %%!!  
    figure;  %%!!  
    hold on
    b = bar(x, y, 'FaceColor', 'flat');  %%!!  
    for i=1:length(x)
        b.CData(i,:) = Colors(rank_inds(i),:);  %%!!  
    end
    xticks(1:num_ROIs);  %%!!  
    xticklabels(networks_ranked);  %%!!  
    %ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['weightX mean']);  %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 15);  %%!!  
    hold off
    saveas(gcf, [res.dir.res '/weightX_barplot_mean.png']);  %%!!  
    close; %% 
end

if ismember(level, {'ROIs_all', 'Dev_ROIs_all', 'AbsDev_ROIs_all'})  %%!!  %%!!  
    % save the ROI weights in .nii files (separately)
    maskfile = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-funPar-4mm-mask-inds.nii.gz']; % 2yr funPar 278 ROIs  %%!!  %%!!  
    nii = load_nii(maskfile);
    W_mask = nii.img;
    num_ROIs = 278;  %%!!  2yr funPar  
    measures = {'Str_8mm2_Harmo', 'Enodal_8mm2_Harmo', 'Elocal_8mm2_Harmo', 'McosSim2_Harmo', 'Gradient1_AlignedToHCP_Harmo', 'Gradient2_AlignedToHCP_Harmo'};  %%!!  %%!!  
    %WeightX = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['wX']);  %%!!  
    weightX_best = WeightX_align(res.frwork.split.best, :);  %%!!  %%!!  
    for mm = 1:length(measures)
        measure = measures{mm};  %%!!  
        W_best = zeros(size(W_mask), 'single');
        for rr=1:num_ROIs
            W_best(W_mask==rr) = weightX_best((mm-1)*num_ROIs+rr);  %%!!  %%!!  
        end
        nii.img = W_best;
        save_nii(nii, [res.dir.res '/weightX_W_best_' measure '.nii.gz']);  %%!!  %%!!  
    end    
    weightX_mean = mean(WeightX_align, 1);  %%!!  %%!!  
    for mm = 1:length(measures)
        measure = measures{mm};  %%!!  
        W_mean = zeros(size(W_mask), 'single');
        for rr=1:num_ROIs
            W_mean(W_mask==rr) = weightX_mean((mm-1)*num_ROIs+rr);  %%!!  %%!!  
        end
        nii.img = W_mean;
        save_nii(nii, [res.dir.res '/weightX_W_mean_' measure '.nii.gz']);  %%!!  %%!!  
    end
end

Correl = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['correl']);  %%!!  
correl_best = Correl(res.frwork.split.best);
correl_mean = mean(Correl);
disp({'Best Corr: ' correl_best});
disp({'Mean Corr: ' correl_mean});

SimWx = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['simwx']);  %%!!  
simwx_mean = mean(SimWx(:));
disp({'Mean SimWx: ' simwx_mean});

% get and save the structure correlations/loadings of entire dataset (different for each split since weights are different; best/mean; based on the aligned weights)
mods = {'X', 'Y'};
Loadings_align = {};
SimLs = {};
for mo = 1:length(mods)
    mod = mods{mo};
    Weight_align = Weights_align{mo};
    Loading_align = zeros(size(Weight_align));
    for split = 1:res.frwork.split.nall
        weight = Weight_align(split, :)';
        % Load data in input space
        [trdata, trid, tedata, teid] = load_data(res, {mod}, 'osplit', split);
        data = concat_data(trdata, tedata, {mod}, trid, teid);  %%!!  %
        % Project data in input space
        P_tr = calc_proj(data.(mod), weight);  %%!!  actually the same - at least for pca-cca  %%!!  tr
        % Compute correlation between input data and projection
        Loading_align(split, :) = corr(P_tr, data.(mod), 'rows', 'pairwise')';  %%!!  tr
    end
    Loadings_align{mo} = Loading_align;
    type = strsplit(cfg.machine.simw, '-'); % type of similarity measure
    [~, sim_all] = calc_stability(Loading_align', type{:});  %%!!  %%!!  
    if length(sim_all) > 1
        s = length(sim_all);
        sim_all = reshape(sim_all(~eye(s)), s-1, s); % remove diagonal entries
    end
    SimLs{mo} = sim_all';  %%!!  %%!!  
end
LoadingX_align = Loadings_align{1};
LoadingY_align = Loadings_align{2};
SimLx = SimLs{1};
SimLy = SimLs{2};
simlx_mean = mean(SimLx(:));
disp({'Mean SimLx: ' simlx_mean});
save([res.dir.res '/Loadings_align.mat'], 'WeightX_raw', 'WeightY_raw', 'WeightX_align', 'WeightY_align', 'LoadingX_align', 'LoadingY_align', 'SimLx', 'SimLy', 'simlx_mean');  %%!!  

if strcmp(level, 'FC_Matrices')
    % plot the X loadings (FC_Matrices)
    load('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/funpar_8Net_allinfo.mat');  %%!!  
    num_ROIs = 278;  %%!!  2yr funPar  
    %LoadingX = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['wX']);  %%!!  
    loadingX_best = LoadingX_align(res.frwork.split.best, :);  %%!!  %%!!  
    M = zeros(num_ROIs, num_ROIs);
    M(triu(true(size(M)), 1)) = loadingX_best;  %%!!  
    M = M + M';
    M_grouped = M(group_inds, group_inds);  %%!!  %%!!  
    imagesc(M_grouped); 
    colorbar;
    caxis([-0.5 0.5]); % Set the colorbar limits
    saveas(gcf, [res.dir.res '/loadingX_M_grouped_best.png']);  %%!!  
    close(gcf);
    loadingX_mean = mean(LoadingX_align, 1);  %%!!  %%!!  
    M = zeros(num_ROIs, num_ROIs);
    M(triu(true(size(M)), 1)) = loadingX_mean;  %%!!  
    M = M + M';
    M_grouped = M(group_inds, group_inds);  %%!!  %%!!  
    imagesc(M_grouped); 
    colorbar;
    caxis([-0.5 0.5]); % Set the colorbar limits
    saveas(gcf, [res.dir.res '/loadingX_M_grouped_mean.png']);  %%!!  
    close(gcf);
end

if strcmp(level, 'ROIs')
    % save the ROI loadings in .nii files
    maskfile = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-funPar-4mm-mask-inds.nii.gz']; % 2yr funPar 278 ROIs  %%!!  %%!!  
    nii = load_nii(maskfile);
    W_mask = nii.img;
    num_ROIs = 278;  %%!!  2yr funPar  
    %LoadingX = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['wX']);  %%!!  
    loadingX_best = LoadingX_align(res.frwork.split.best, :);  %%!!  %%!!  
    W_best = zeros(size(W_mask), 'single');
    for rr=1:num_ROIs
        W_best(W_mask==rr) = loadingX_best(rr);
    end
    nii.img = W_best;
    save_nii(nii, [res.dir.res '/loadingX_W_best.nii.gz']);  %%!!  
    loadingX_mean = mean(LoadingX_align, 1);  %%!!  %%!!  
    W_mean = zeros(size(W_mask), 'single');
    for rr=1:num_ROIs
        W_mean(W_mask==rr) = loadingX_mean(rr);
    end
    nii.img = W_mean;
    save_nii(nii, [res.dir.res '/loadingX_W_mean.nii.gz']);  %%!!  
end

if strcmp(level, 'Networks')
    % plot the bar plots of Network loadings
    ROIs = {'Visual', 'Somatomotor', 'Dorsal-A', 'Ventral-A', 'Limbic', 'Frontoparietal', 'Default', 'Subcortical'};  %% 8    %%!!  %%!!  Yeo 8 networks (Ventral Attention is Salience)
    networks = {'VIS', 'SMN', 'DAN', 'SAL', 'LIM', 'FPN', 'DMN', 'SUB'};  %% 8    %%!!  updated!!  
    num_ROIs = length(ROIs); % 
    Colors = [120 18 134; 70 130 180; 0 118 14; 196 58 250; 220 248 164; 230 148 34; 205 62 78; 128 128 128] / 255;  %%!!  RGB values for Yeo 8 networks  
    %LoadingX = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['wX']);  %%!!  
    loadingX_best = LoadingX_align(res.frwork.split.best, :);  %%!!  %%!!  
    [~, rank_inds] = sort(loadingX_best, 'descend');  %%!!  
    loadingX_best_ranked = loadingX_best(rank_inds);
    networks_ranked = networks(rank_inds);
    x = 1:num_ROIs;  %%!!  
    y = loadingX_best_ranked;  %%!!  
    figure;  %%!!  
    hold on
    b = bar(x, y, 'FaceColor', 'flat');  %%!!  
    for i=1:length(x)
        b.CData(i,:) = Colors(rank_inds(i),:);  %%!!  
    end
    xticks(1:num_ROIs);  %%!!  
    xticklabels(networks_ranked);  %%!!  
    %ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['loadingX best split']);  %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 15);  %%!!  
    hold off
    saveas(gcf, [res.dir.res '/loadingX_barplot_best.png']);  %%!!  
    close; %% 
    loadingX_mean = mean(LoadingX_align, 1);  %%!!  %%!!  
    [~, rank_inds] = sort(loadingX_mean, 'descend');  %%!!  
    loadingX_mean_ranked = loadingX_mean(rank_inds);
    networks_ranked = networks(rank_inds);
    x = 1:num_ROIs;  %%!!  
    y = loadingX_mean_ranked;  %%!!  
    figure;  %%!!  
    hold on
    b = bar(x, y, 'FaceColor', 'flat');  %%!!  
    for i=1:length(x)
        b.CData(i,:) = Colors(rank_inds(i),:);  %%!!  
    end
    xticks(1:num_ROIs);  %%!!  
    xticklabels(networks_ranked);  %%!!  
    %ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['loadingX mean']);  %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 15);  %%!!  
    hold off
    saveas(gcf, [res.dir.res '/loadingX_barplot_mean.png']);  %%!!  
    close; %% 
end

if ismember(level, {'ROIs_all', 'Dev_ROIs_all', 'AbsDev_ROIs_all'})  %%!!  %%!!  
    % save the ROI loadings in .nii files (separately)
    maskfile = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-funPar-4mm-mask-inds.nii.gz']; % 2yr funPar 278 ROIs  %%!!  %%!!  
    nii = load_nii(maskfile);
    W_mask = nii.img;
    num_ROIs = 278;  %%!!  2yr funPar  
    measures = {'Str_8mm2_Harmo', 'Enodal_8mm2_Harmo', 'Elocal_8mm2_Harmo', 'McosSim2_Harmo', 'Gradient1_AlignedToHCP_Harmo', 'Gradient2_AlignedToHCP_Harmo'};  %%!!  %%!!  
    %LoadingX = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['wX']);  %%!!  
    loadingX_best = LoadingX_align(res.frwork.split.best, :);  %%!!  %%!!  
    for mm = 1:length(measures)
        measure = measures{mm};  %%!!  
        W_best = zeros(size(W_mask), 'single');
        for rr=1:num_ROIs
            W_best(W_mask==rr) = loadingX_best((mm-1)*num_ROIs+rr);  %%!!  %%!!  
        end
        nii.img = W_best;
        save_nii(nii, [res.dir.res '/loadingX_W_best_' measure '.nii.gz']);  %%!!  %%!!  
    end    
    loadingX_mean = mean(LoadingX_align, 1);  %%!!  %%!!  
    for mm = 1:length(measures)
        measure = measures{mm};  %%!!  
        W_mean = zeros(size(W_mask), 'single');
        for rr=1:num_ROIs
            W_mean(W_mask==rr) = loadingX_mean((mm-1)*num_ROIs+rr);  %%!!  %%!!  
        end
        nii.img = W_mean;
        save_nii(nii, [res.dir.res '/loadingX_W_mean_' measure '.nii.gz']);  %%!!  %%!!  
    end
end

if ismember(Y_label, {'AllBehavior4', 'AllBehavior6', 'AllBehavior8', 'AllBehavior10'})
    % plot the bar plots of Y loadings (LoadingY_align)
    Behavs = {['IQ' Y_label(12:end)], ['Anxiety' Y_label(12:end)], ['Depression' Y_label(12:end)]};  %%!!  %%!!  
    num_Behavs = length(Behavs); % 
    Colors = [0 0.4470 0.7410; 0.6350 0.0780 0.1840; 0.6350 0.0780 0.1840];  %%!!  RGB values for 3 Behaviors  
    %LoadingX = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['wX']);  %%!!  
    loadingY_best = LoadingY_align(res.frwork.split.best, :);  %%!!  %%!!  
    [~, rank_inds] = sort(loadingY_best, 'descend');  %%!!  
    loadingY_best_ranked = loadingY_best(rank_inds);
    Behavs_ranked = Behavs(rank_inds);
    x = 1:num_Behavs;  %%!!  
    y = loadingY_best_ranked;  %%!!  
    figure;  %%!!  
    hold on
    b = bar(x, y, 'FaceColor', 'flat');  %%!!  
    for i=1:length(x)
        b.CData(i,:) = Colors(rank_inds(i),:);  %%!!  
    end
    xticks(1:num_Behavs);  %%!!  
    xticklabels(Behavs_ranked);  %%!!  
    %ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['loadingY best split']);  %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 15);  %%!!  
    hold off
    saveas(gcf, [res.dir.res '/loadingY_barplot_best.png']);  %%!!  
    close; %% 
    loadingY_mean = mean(LoadingY_align, 1);  %%!!  %%!!  
    [~, rank_inds] = sort(loadingY_mean, 'descend');  %%!!  
    loadingY_mean_ranked = loadingY_mean(rank_inds);
    Behavs_ranked = Behavs(rank_inds);
    x = 1:num_Behavs;  %%!!  
    y = loadingY_mean_ranked;  %%!!  
    figure;  %%!!  
    hold on
    b = bar(x, y, 'FaceColor', 'flat');  %%!!  
    for i=1:length(x)
        b.CData(i,:) = Colors(rank_inds(i),:);  %%!!  
    end
    xticks(1:num_Behavs);  %%!!  
    xticklabels(Behavs_ranked);  %%!!  
    %ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['loadingY mean']);  %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 15);  %%!!  
    hold off
    saveas(gcf, [res.dir.res '/loadingY_barplot_mean.png']);  %%!!  
    close; %% 
end

if ismember(Y_label, {'AllCognition14', 'AllCognition16', 'AllCognition18', 'AllCognition110'})
    % plot the bar plots of Y loadings (LoadingY_align)
    Behavs = {['IQ' Y_label(14:end)], ['WM_BRIEF' Y_label(14:end)], ['WM_SB' Y_label(14:end)]};  %%!!  %%!!  
    num_Behavs = length(Behavs); % 
    Colors = [0 0.4470 0.7410; 0 0.4470 0.7410; 0 0.4470 0.7410];  %%!!  RGB values for 3 Behaviors  
    %LoadingX = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['wX']);  %%!!  
    loadingY_best = LoadingY_align(res.frwork.split.best, :);  %%!!  %%!!  
    [~, rank_inds] = sort(loadingY_best, 'descend');  %%!!  
    loadingY_best_ranked = loadingY_best(rank_inds);
    Behavs_ranked = Behavs(rank_inds);
    x = 1:num_Behavs;  %%!!  
    y = loadingY_best_ranked;  %%!!  
    figure;  %%!!  
    hold on
    b = bar(x, y, 'FaceColor', 'flat');  %%!!  
    for i=1:length(x)
        b.CData(i,:) = Colors(rank_inds(i),:);  %%!!  
    end
    xticks(1:num_Behavs);  %%!!  
    xticklabels(Behavs_ranked);  %%!!  
    %ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['loadingY best split']);  %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 15);  %%!!  
    hold off
    saveas(gcf, [res.dir.res '/loadingY_barplot_best.png']);  %%!!  
    close; %% 
    loadingY_mean = mean(LoadingY_align, 1);  %%!!  %%!!  
    [~, rank_inds] = sort(loadingY_mean, 'descend');  %%!!  
    loadingY_mean_ranked = loadingY_mean(rank_inds);
    Behavs_ranked = Behavs(rank_inds);
    x = 1:num_Behavs;  %%!!  
    y = loadingY_mean_ranked;  %%!!  
    figure;  %%!!  
    hold on
    b = bar(x, y, 'FaceColor', 'flat');  %%!!  
    for i=1:length(x)
        b.CData(i,:) = Colors(rank_inds(i),:);  %%!!  
    end
    xticks(1:num_Behavs);  %%!!  
    xticklabels(Behavs_ranked);  %%!!  
    %ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['loadingY mean']);  %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 15);  %%!!  
    hold off
    saveas(gcf, [res.dir.res '/loadingY_barplot_mean.png']);  %%!!  
    close; %% 
end

if ismember(Y_label, {'AllEmotion4', 'AllEmotion6', 'AllEmotion8', 'AllEmotion10'})
    % plot the bar plots of Y loadings (LoadingY_align)
    Behavs = {['Anxiety' Y_label(11:end)], ['Depression' Y_label(11:end)]};  %%!!  %%!!  ['IQ' Y_label(11:end)], 
    num_Behavs = length(Behavs); % 
    Colors = [0.6350 0.0780 0.1840; 0.6350 0.0780 0.1840];  %%!!  RGB values for 2 Emotions  0 0.4470 0.7410; 
    %LoadingX = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['wX']);  %%!!  
    loadingY_best = LoadingY_align(res.frwork.split.best, :);  %%!!  %%!!  
    [~, rank_inds] = sort(loadingY_best, 'descend');  %%!!  
    loadingY_best_ranked = loadingY_best(rank_inds);
    Behavs_ranked = Behavs(rank_inds);
    x = 1:num_Behavs;  %%!!  
    y = loadingY_best_ranked;  %%!!  
    figure;  %%!!  
    hold on
    b = bar(x, y, 'FaceColor', 'flat');  %%!!  
    for i=1:length(x)
        b.CData(i,:) = Colors(rank_inds(i),:);  %%!!  
    end
    xticks(1:num_Behavs);  %%!!  
    xticklabels(Behavs_ranked);  %%!!  
    %ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['loadingY best split']);  %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 15);  %%!!  
    hold off
    saveas(gcf, [res.dir.res '/loadingY_barplot_best.png']);  %%!!  
    close; %% 
    loadingY_mean = mean(LoadingY_align, 1);  %%!!  %%!!  
    [~, rank_inds] = sort(loadingY_mean, 'descend');  %%!!  
    loadingY_mean_ranked = loadingY_mean(rank_inds);
    Behavs_ranked = Behavs(rank_inds);
    x = 1:num_Behavs;  %%!!  
    y = loadingY_mean_ranked;  %%!!  
    figure;  %%!!  
    hold on
    b = bar(x, y, 'FaceColor', 'flat');  %%!!  
    for i=1:length(x)
        b.CData(i,:) = Colors(rank_inds(i),:);  %%!!  
    end
    xticks(1:num_Behavs);  %%!!  
    xticklabels(Behavs_ranked);  %%!!  
    %ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['loadingY mean']);  %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 15);  %%!!  
    hold off
    saveas(gcf, [res.dir.res '/loadingY_barplot_mean.png']);  %%!!  
    close; %% 
end

if ismember(Y_label, {'AllCognition24', 'AllCognition26', 'AllCognition28', 'AllCognition210'})
    % plot the bar plots of Y loadings (LoadingY_align)
    Behavs = {['WM_BRIEF' Y_label(14:end)], ['WM_SB' Y_label(14:end)]};  %%!!  %%!!  ['IQ' Y_label(11:end)], 
    num_Behavs = length(Behavs); % 
    Colors = [0 0.4470 0.7410; 0 0.4470 0.7410];  %%!!  RGB values for 2 Emotions  0 0.4470 0.7410; 
    %LoadingX = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['wX']);  %%!!  
    loadingY_best = LoadingY_align(res.frwork.split.best, :);  %%!!  %%!!  
    [~, rank_inds] = sort(loadingY_best, 'descend');  %%!!  
    loadingY_best_ranked = loadingY_best(rank_inds);
    Behavs_ranked = Behavs(rank_inds);
    x = 1:num_Behavs;  %%!!  
    y = loadingY_best_ranked;  %%!!  
    figure;  %%!!  
    hold on
    b = bar(x, y, 'FaceColor', 'flat');  %%!!  
    for i=1:length(x)
        b.CData(i,:) = Colors(rank_inds(i),:);  %%!!  
    end
    xticks(1:num_Behavs);  %%!!  
    xticklabels(Behavs_ranked);  %%!!  
    %ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['loadingY best split']);  %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 15);  %%!!  
    hold off
    saveas(gcf, [res.dir.res '/loadingY_barplot_best.png']);  %%!!  
    close; %% 
    loadingY_mean = mean(LoadingY_align, 1);  %%!!  %%!!  
    [~, rank_inds] = sort(loadingY_mean, 'descend');  %%!!  
    loadingY_mean_ranked = loadingY_mean(rank_inds);
    Behavs_ranked = Behavs(rank_inds);
    x = 1:num_Behavs;  %%!!  
    y = loadingY_mean_ranked;  %%!!  
    figure;  %%!!  
    hold on
    b = bar(x, y, 'FaceColor', 'flat');  %%!!  
    for i=1:length(x)
        b.CData(i,:) = Colors(rank_inds(i),:);  %%!!  
    end
    xticks(1:num_Behavs);  %%!!  
    xticklabels(Behavs_ranked);  %%!!  
    %ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['loadingY mean']);  %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 15);  %%!!  
    hold off
    saveas(gcf, [res.dir.res '/loadingY_barplot_mean.png']);  %%!!  
    close; %% 
end

if ismember(Y_label, {'MulSubs1', 'MulSubs2'})
    % plot the bar plots of Y loadings (LoadingY_align)
    Behavs = {['GM' Y_label(8:end)], ['VR' Y_label(8:end)], ['FM' Y_label(8:end)], ['RL' Y_label(8:end)], ['EL' Y_label(8:end)]};  %%!!  %%!!  Gross Motor, Visual Reception, Fine Motor, Receptive Language, Expressive Language
    num_Behavs = length(Behavs); % 
    Colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0 0.4470 0.7410; 0.9290 0.6940 0.1250; 0.9290 0.6940 0.1250];  %%!!  RGB values for 5 Behaviors  (b for Motor, r for Cognitive, y for Language)
    %LoadingX = loadmat(res, fullfile(res.dir.res, 'model.mat'), ['wX']);  %%!!  
    loadingY_best = LoadingY_align(res.frwork.split.best, :);  %%!!  %%!!  
    [~, rank_inds] = sort(loadingY_best, 'descend');  %%!!  
    loadingY_best_ranked = loadingY_best(rank_inds);
    Behavs_ranked = Behavs(rank_inds);
    x = 1:num_Behavs;  %%!!  
    y = loadingY_best_ranked;  %%!!  
    figure;  %%!!  
    hold on
    b = bar(x, y, 'FaceColor', 'flat');  %%!!  
    for i=1:length(x)
        b.CData(i,:) = Colors(rank_inds(i),:);  %%!!  
    end
    xticks(1:num_Behavs);  %%!!  
    xticklabels(Behavs_ranked);  %%!!  
    %ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['loadingY best split']);  %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 15);  %%!!  
    hold off
    saveas(gcf, [res.dir.res '/loadingY_barplot_best.png']);  %%!!  
    close; %% 
    loadingY_mean = mean(LoadingY_align, 1);  %%!!  %%!!  
    [~, rank_inds] = sort(loadingY_mean, 'descend');  %%!!  
    loadingY_mean_ranked = loadingY_mean(rank_inds);
    Behavs_ranked = Behavs(rank_inds);
    x = 1:num_Behavs;  %%!!  
    y = loadingY_mean_ranked;  %%!!  
    figure;  %%!!  
    hold on
    b = bar(x, y, 'FaceColor', 'flat');  %%!!  
    for i=1:length(x)
        b.CData(i,:) = Colors(rank_inds(i),:);  %%!!  
    end
    xticks(1:num_Behavs);  %%!!  
    xticklabels(Behavs_ranked);  %%!!  
    %ylim(ylims(mm,:)); %%   %%!!  %%!!  %%!!  
    %xlabel('Ranked Network');  %%!!  %%!!  
    ylabel(['loadingY mean']);  %%!!  
    %title([group]); %% 
    set(gca, 'fontsize', 15);  %%!!  
    hold off
    saveas(gcf, [res.dir.res '/loadingY_barplot_mean.png']);  %%!!  
    close; %% 
end

if cfg.frwork.split.nout == 1
    % calc training canoncorr p and corr(u,v) p just for information (not
    % really meaningful since we use few PCs to avoid overfitting, fewer features
    % will always give larger p - test perm p is the key for generalizability instead)  
    load([res.dir.project 'data/X.mat']); % X
    load([res.dir.project 'data/Y.mat']); % Y
    load([res.dir.project 'data/Normal_I.mat']); % Normal_I
    load([res.dir.frwork '/load/svd/tr_svdx_split_1_1.mat']); % RX
    load([res.dir.frwork '/load/svd/tr_svdy_split_1_1.mat']); % RY
    load([res.dir.res '/param_1.mat']); % param.PCAx / param.PCAy
    YY = Y(Normal_I, :);  %%!!  %%!!  
    % Impute column-wise mean
    for i = 1:size(YY, 2)
        col = YY(:, i);
        YY(isnan(col), i) = mean(col(~isnan(col)));
    end
    [~,~,r_orig,~,~,stats_orig] = canoncorr(X(Normal_I, :), YY); %% likely sig  %%!!  %%!!  
    [~,~,r_pca,U_pca,V_pca,stats_pca] = canoncorr(RX(:, 1:param.PCAx), RY(:, 1:param.PCAy)); %% likely non-sig
    [r_corr, p_corr] = corr(U_pca(:, 1), V_pca(:, 1)); %% likely sig
    save([res.dir.res '/training_p_info.mat'], 'r_orig', 'stats_orig', 'r_pca', 'U_pca', 'V_pca', 'stats_pca', 'r_corr', 'p_corr');
end


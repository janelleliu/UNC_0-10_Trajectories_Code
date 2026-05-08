function CCA4_1_UNC_Tra_Desc(level, measure, age, age_num, Y_label)
% UNC_Tra_Desc
%
% # Syntax
%   UNC_Tra_Desc
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
cfg.dir.project = ['/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/CCA4_M_FC_Z_All_for_CCA_Ages/' Y_label '_' level '_' measure '_' age '/'];  %%!!  %%!!  

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
cfg.machine.param.PCAx = 50;  %%!!  fixed for the descriptive framework  %%!!  NEED TO CHANGE!!!!    40-70    60 / 50 / 40 / 
cfg.machine.param.PCAy = 1;  %%!!  fixed for the descriptive framework

%cfg.machine.metric = {'trcorrel' 'correl' 'simwx' 'simwy' ...
%    'trexvarx' 'trexvary'};
%cfg.machine.param.crit = 'correl';
%cfg.machine.simw = 'correlation-Pearson';

% Framework settings
cfg.frwork.name = 'permutation'; %% 'holdout'
nperm = 1000; %% 1000 / 2000  %%!!  %%!!  
cfg.frwork.flag = ['_nperm' num2str(nperm)]; %% the descriptive framework  %%!!  
%cfg.frwork.nlevel = 1;
%cfg.frwork.split.nout = 10;
%cfg.frwork.split.nin = 10;

% Deflation settings
cfg.defl.name = 'generalized';

% Environment settings
cfg.env.comp = 'local';
cfg.env.verbose = 3;  %%!!  

% % Number of permutations
cfg.stat.nperm = nperm; %% 
   
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

% Plot data projections
plot_proj(res, {'X' 'Y'}, res.frwork.level, 'osplit', ...
    1, 'none', '2d', ...
    'gen.figure.ext', '.svg', ... %% 
    'gen.figure.Position', [0 0 500 400], ...
    'gen.axes.Position', [0.1798 0.1560 0.7252 0.7690], ...
    'gen.axes.XLim', [-0.6 0.6], 'gen.axes.YLim', [-0.6 0.6], ...  %%!!  
    'gen.axes.FontSize', 10, 'gen.legend.FontSize', 10, ...
    'gen.legend.Location', 'best', ...
    'proj.scatter.SizeData', 30, ...
    'proj.scatter.MarkerFaceColor', [0.3 0.3 0.9], ...
    'proj.scatter.MarkerEdgeColor', 'k', 'proj.lsline', 'on', ...
    'proj.xlabel', ['Brain latent variable ' level ' ' measure ' at ' num2str(age_num) 'YR'], ...  %%!!  
    'proj.ylabel', [Y_label ' latent variable']);
close;  %%!!  

%{
% Plot brain weights as horizontal bar plot (flip the weights!!!!)
plot_weight(res, 'X', 'behav', 1, 'behav_horz', ... %% 
    'gen.figure.ext', '.svg', ... %% 
    'gen.axes.FontSize', 8, 'gen.legend.FontSize', 8, ...
    'gen.axes.XLim', [-1.2 1.2], 'gen.weight.flip', 1, ...  %%!!  
    'behav.weight.sorttype', 'sign', 'behav.weight.numtop', 15, ...
    'behav.weight.norm', 'minmax', ... %% 
    'behav.ylabel', ['Brain FC variables ' measure], ...  %%!!  %%!!  
    'behav.xlabel', 'Flipped Weight', ...  %%!!  
    'behav.file.label', ['/media/zhark2/glab4/Haitao/UNC_Trajectory/M_FC_Z_All_for_CCA_Ages/LabelsX_' measure '.csv']);  %%!!  %%!!  
close;  %%!!  

% Plot brain structure correlations as horizontal bar plot (flip the weights!!!!)  
plot_weight(res, 'X', 'behav', 1, 'behav_horz', ... %% 
    'gen.figure.ext', '.svg', ... %% 
    'gen.axes.FontSize', 8, 'gen.legend.FontSize', 8, ...
    'gen.axes.XLim', [-0.6 0.6], 'gen.weight.flip', 1, ...  %%!!  
    'gen..weight.type', 'correlation', ...  %%!!    %%!!  Structure Correlation  
    'behav.weight.sorttype', 'sign', 'behav.weight.numtop', 15, ...
    'behav.weight.norm', 'none', ... %% minmax for weight  
    'behav.ylabel', ['Brain FC variables ' measure], ...  %%!!  %%!!  
    'behav.xlabel', 'Flipped Structure Correlation', ...  %%!!    %%!!  Structure Correlation  
    'behav.file.label', ['/media/zhark2/glab4/Haitao/UNC_Trajectory/M_FC_Z_All_for_CCA_Ages/LabelsX_' measure '.csv']);  %%!!  %%!!  
close;  %%!!  
%}



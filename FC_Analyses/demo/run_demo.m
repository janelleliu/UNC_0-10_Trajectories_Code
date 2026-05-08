%% CCA demo for FC Trajectories code submission using simulated data

clear; clc;

thisFile = mfilename('fullpath');
demoDir = fileparts(thisFile);
dataDir = fullfile(demoDir, 'data');
outputDir = fullfile(demoDir, 'outputs');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

oldOutputs = [dir(fullfile(outputDir, 'demo_*.csv')); dir(fullfile(outputDir, 'demo_*.png'))];
for idx = 1:numel(oldOutputs)
    delete(fullfile(outputDir, oldOutputs(idx).name));
end

subjects = readtable(fullfile(dataDir, 'simulated_subjects.csv'));
brainFeatures = readtable(fullfile(dataDir, 'simulated_brain_features.csv'));
behavior = readtable(fullfile(dataDir, 'simulated_behavior.csv'));
covariates = readtable(fullfile(dataDir, 'simulated_covariates.csv'));

subjects.subject_id = string(subjects.subject_id);
subjects.sex = string(subjects.sex);
subjects.group = string(subjects.group);
brainFeatures.subject_id = string(brainFeatures.subject_id);
behavior.subject_id = string(behavior.subject_id);
covariates.subject_id = string(covariates.subject_id);

if ~isequal(subjects.subject_id, brainFeatures.subject_id) || ...
        ~isequal(subjects.subject_id, behavior.subject_id) || ...
        ~isequal(subjects.subject_id, covariates.subject_id)
    error('Simulated subject, brain, behavior, and covariate files must use the same subject order.');
end

brainVariableNames = brainFeatures.Properties.VariableNames(2:end);
behaviorVariableNames = behavior.Properties.VariableNames(2:end);
covariateVariableNames = covariates.Properties.VariableNames(2:end);

brainMatrix = table2array(brainFeatures(:, brainVariableNames));
behaviorMatrix = table2array(behavior(:, behaviorVariableNames));
covariateMatrix = table2array(covariates(:, covariateVariableNames));

brainResiduals = residualizeMatrix(brainMatrix, covariateMatrix);
behaviorResiduals = residualizeMatrix(behaviorMatrix, covariateMatrix);
[brainZ, keepBrain] = zscoreColumns(brainResiduals);
[behaviorZ, keepBehavior] = zscoreColumns(behaviorResiduals);
brainVariableNames = brainVariableNames(keepBrain);
behaviorVariableNames = behaviorVariableNames(keepBehavior);

ccaMethod = "QR/SVD fallback";
if exist('canoncorr', 'file') == 2
    try
        [~, ~, canonicalCorr, brainScores, behaviorScores] = canoncorr(brainZ, behaviorZ);
        ccaMethod = "canoncorr";
    catch
        [canonicalCorr, brainScores, behaviorScores] = ccaBySvd(brainZ, behaviorZ);
    end
else
    [canonicalCorr, brainScores, behaviorScores] = ccaBySvd(brainZ, behaviorZ);
end

nCcaDims = min([3, numel(canonicalCorr), size(brainScores, 2), size(behaviorScores, 2)]);
canonicalCorr = canonicalCorr(1:nCcaDims);
brainScores = brainScores(:, 1:nCcaDims);
behaviorScores = behaviorScores(:, 1:nCcaDims);
brainLoadings = correlationLoadings(brainZ, brainScores);
behaviorLoadings = correlationLoadings(behaviorZ, behaviorScores);

ccaResults = table((1:nCcaDims)', canonicalCorr(:), repmat(ccaMethod, nCcaDims, 1), ...
    'VariableNames', {'canonical_dimension', 'canonical_correlation', 'method'});
writetable(ccaResults, fullfile(outputDir, 'demo_cca_results.csv'));

scoreTable = table(subjects.subject_id, subjects.group, ...
    'VariableNames', {'subject_id', 'group'});
for dimIdx = 1:nCcaDims
    scoreTable.(sprintf('brain_canonical_score%d', dimIdx)) = brainScores(:, dimIdx);
    scoreTable.(sprintf('behavior_canonical_score%d', dimIdx)) = behaviorScores(:, dimIdx);
end
writetable(scoreTable, fullfile(outputDir, 'demo_cca_subject_scores.csv'));

ccaBrainLoadings = makeLoadingTable(brainVariableNames, brainLoadings, nCcaDims);
writetable(ccaBrainLoadings, fullfile(outputDir, 'demo_cca_loadings_brain.csv'));

ccaBehaviorLoadings = makeLoadingTable(behaviorVariableNames, behaviorLoadings, nCcaDims);
writetable(ccaBehaviorLoadings, fullfile(outputDir, 'demo_cca_loadings_behavior.csv'));

figure('Visible', 'off');
hold on;
groups = unique(subjects.group, 'stable');
groupColors = lines(numel(groups));
for groupIdx = 1:numel(groups)
    groupMask = subjects.group == groups(groupIdx);
    scatter(brainScores(groupMask, 1), behaviorScores(groupMask, 1), 65, groupColors(groupIdx, :), 'filled', 'DisplayName', char(groups(groupIdx)));
end
xlabel('Brain canonical score 1');
ylabel('Behavior canonical score 1');
title(sprintf('Simulated CCA demo: r = %.2f', canonicalCorr(1)));
grid on;
legend('Location', 'best');
saveas(gcf, fullfile(outputDir, 'demo_cca_scores.png'));
close(gcf);

figure('Visible', 'off');
tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
nexttile;
barh(categorical(string(brainVariableNames)), brainLoadings(:, 1));
xlabel('Loading on canonical dimension 1');
title('Brain variable loadings');
grid on;
nexttile;
barh(categorical(string(behaviorVariableNames)), behaviorLoadings(:, 1));
xlabel('Loading on canonical dimension 1');
title('Behavior variable loadings');
grid on;
saveas(gcf, fullfile(outputDir, 'demo_cca_loadings.png'));
close(gcf);

fprintf('FC Trajectories CCA demo completed.\n');
fprintf('Loaded %d simulated subjects, %d brain variables, and %d behavior variables.\n', height(subjects), numel(brainVariableNames), numel(behaviorVariableNames));
fprintf('Residualized brain and behavior variables for %d simulated covariates before CCA.\n', numel(covariateVariableNames));
fprintf('CCA completed using %s with first canonical correlation %.3f.\n', ccaMethod, canonicalCorr(1));
fprintf('Outputs written to: %s\n', outputDir);

function residuals = residualizeMatrix(x, covariates)
    design = [ones(size(covariates, 1), 1), covariates];
    residuals = x - design * (design \ x);
end

function [z, keepColumns] = zscoreColumns(x)
    mu = mean(x, 1);
    sigma = std(x, 0, 1);
    keepColumns = sigma > 1e-10;
    z = (x(:, keepColumns) - mu(keepColumns)) ./ sigma(keepColumns);
end

function [canonicalCorr, brainScores, behaviorScores] = ccaBySvd(x, y)
    [qx, ~] = qr(x, 0);
    [qy, ~] = qr(y, 0);
    [leftVectors, singularValues, rightVectors] = svd(qx' * qy, 'econ');
    canonicalCorr = diag(singularValues);
    brainScores = qx * leftVectors;
    behaviorScores = qy * rightVectors;
end

function loadings = correlationLoadings(variables, scores)
    standardizedVariables = standardizeNoDrop(variables);
    standardizedScores = standardizeNoDrop(scores);
    loadings = standardizedVariables' * standardizedScores / (size(standardizedVariables, 1) - 1);
end

function z = standardizeNoDrop(x)
    sigma = std(x, 0, 1);
    sigma(sigma <= 1e-10) = 1;
    z = (x - mean(x, 1)) ./ sigma;
end

function loadingTable = makeLoadingTable(variableNames, loadings, nCcaDims)
    nRows = numel(variableNames) * nCcaDims;
    dimension = zeros(nRows, 1);
    variable = strings(nRows, 1);
    loading = zeros(nRows, 1);
    rowIdx = 0;
    for dimIdx = 1:nCcaDims
        for varIdx = 1:numel(variableNames)
            rowIdx = rowIdx + 1;
            dimension(rowIdx) = dimIdx;
            variable(rowIdx) = string(variableNames{varIdx});
            loading(rowIdx) = loadings(varIdx, dimIdx);
        end
    end
    loadingTable = table(dimension, variable, loading, ...
        'VariableNames', {'canonical_dimension', 'variable', 'loading'});
end

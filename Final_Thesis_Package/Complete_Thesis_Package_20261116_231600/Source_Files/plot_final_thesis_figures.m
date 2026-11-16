
%% FINAL THESIS FIGURES - PUBLICATION-READY VERSION
% Combined 200-run results
%
% Generates six figures comparing five scheduling algorithms
% across 20, 40 and 60 users.
%
% Error bars represent exact 95% t-based confidence intervals.
%
% No simulations are rerun.
% No original results are modified.

clear;
clc;
close all;

%% 1. LOAD COMBINED RESULTS

dataFile = "combined_200run_results.mat";

if ~isfile(dataFile)
    error("Cannot find %s. Place this script in the project folder.", ...
        dataFile);
end

S = load(dataFile);

required = ["results20_combined", ...
            "results40_combined", ...
            "results60_combined"];

for k = 1:numel(required)

    if ~isfield(S, required(k))
        error("Missing variable in MAT file: %s", required(k));
    end

end

R20 = S.results20_combined;
R40 = S.results40_combined;
R60 = S.results60_combined;

resultsByLoad = {R20, R40, R60};

userCounts = [20 40 60];

algorithms = string(R20.algorithms);

numAlgorithms = numel(algorithms);

numRuns = size(R20.raw.waiting, 1);

if numRuns ~= 200
    warning("Expected 200 runs, but found %d.", numRuns);
end

fprintf("\nLoaded combined experiment results.\n");

%% 2. DEFINE METRICS AND LABELS

metricFields = { ...
    'waiting', ...
    'turnaround', ...
    'fairness', ...
    'efficiencyFairness', ...
    'meanServiceEfficiency', ...
    'utilization'};

metricTitles = { ...
    'Mean Waiting Time', ...
    'Mean Turnaround Time', ...
    'Jain Completion-Rate Fairness', ...
    'Jain Service-Efficiency Fairness', ...
    'Mean Service Efficiency', ...
    'Resource Utilization'};

yLabels = { ...
    'Waiting Time (ms)', ...
    'Turnaround Time (ms)', ...
    'Jain Fairness Index', ...
    'Jain Fairness Index', ...
    'Mean Service Efficiency', ...
    'Resource Utilization'};

fileNames = { ...
    'Figure_1_Waiting_Time', ...
    'Figure_2_Turnaround_Time', ...
    'Figure_3_Completion_Rate_Fairness', ...
    'Figure_4_Service_Efficiency_Fairness', ...
    'Figure_5_Mean_Service_Efficiency', ...
    'Figure_6_Resource_Utilization'};

numMetrics = numel(metricFields);

%% 3. OUTPUT FOLDER

outputFolder = "final_thesis_figures";

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

%% 4. CALCULATE MEANS AND EXACT 95% CONFIDENCE INTERVALS

means = struct();
ciLower = struct();
ciUpper = struct();

for m = 1:numMetrics

    field = metricFields{m};

    means.(field) = zeros(3, numAlgorithms);
    ciLower.(field) = zeros(3, numAlgorithms);
    ciUpper.(field) = zeros(3, numAlgorithms);

    for s = 1:3

        rawData = resultsByLoad{s}.raw.(field);

        n = size(rawData, 1);

        sampleMean = mean(rawData, 1);

        sampleSD = std(rawData, 0, 1);

        tCritical = tinv(0.975, n - 1);

        margin = tCritical .* sampleSD ./ sqrt(n);

        means.(field)(s,:) = sampleMean;

        ciLower.(field)(s,:) = sampleMean - margin;

        ciUpper.(field)(s,:) = sampleMean + margin;

    end

end

%% 5. GENERATE SIX FIGURES

for m = 1:numMetrics

    field = metricFields{m};

    fprintf("\nGenerating %s...\n", fileNames{m});

    %% Create figure

    fig = figure( ...
        'Color', 'white', ...
        'InvertHardcopy', 'on', ...
        'Units', 'pixels', ...
        'Position', [100 100 1200 800], ...
        'Name', metricTitles{m}, ...
        'NumberTitle', 'off');

    %% Create axes

    ax = axes(fig);

    hold(ax, 'on');

    box(ax, 'on');

    grid(ax, 'on');

    %% Explicit white-background publication styling

    ax.Color = 'white';

    ax.XColor = [0 0 0];

    ax.YColor = [0 0 0];

    ax.GridColor = [0.65 0.65 0.65];

    ax.GridAlpha = 0.30;

    ax.MinorGridAlpha = 0.12;

    ax.FontName = 'Arial';

    ax.FontSize = 13;

    ax.LineWidth = 1.2;

    ax.TickDir = 'out';

    ax.Layer = 'top';

    ax.Toolbar.Visible = 'off';

    %% Plot all five algorithms

    for a = 1:numAlgorithms

        y = means.(field)(:,a);

        lowerError = y - ciLower.(field)(:,a);

        upperError = ciUpper.(field)(:,a) - y;

        errorbar( ...
            ax, ...
            userCounts, ...
            y, ...
            lowerError, ...
            upperError, ...
            '-o', ...
            'LineWidth', 2.2, ...
            'MarkerSize', 8, ...
            'MarkerFaceColor', 'auto', ...
            'CapSize', 11, ...
            'DisplayName', algorithms(a));

    end

    %% Axis labels

    xlabel(ax, 'Number of Users', ...
        'FontName', 'Arial', ...
        'FontSize', 15, ...
        'FontWeight', 'bold', ...
        'Color', 'black');

    ylabel(ax, yLabels{m}, ...
        'FontName', 'Arial', ...
        'FontSize', 15, ...
        'FontWeight', 'bold', ...
        'Color', 'black');

    %% Figure title

    title(ax, metricTitles{m}, ...
        'FontName', 'Arial', ...
        'FontSize', 18, ...
        'FontWeight', 'bold', ...
        'Color', 'black');

    %% X-axis formatting

    xticks(ax, userCounts);

    xlim(ax, [17 63]);

    %% Y-axis formatting

    allUpper = ciUpper.(field)(:);

    switch field

        case {'waiting', 'turnaround'}

            % Waiting and turnaround cannot be negative.
            % Confidence intervals extending below zero are
            % displayed only above the physical zero boundary.

            upperLimit = max(allUpper) * 1.12;

            if upperLimit <= 0
                upperLimit = 1;
            end

            ylim(ax, [0 upperLimit]);

        case {'fairness', 'efficiencyFairness', ...
              'meanServiceEfficiency'}

            % These metrics are bounded between zero and one.

            ylim(ax, [0 1]);

            yticks(ax, 0:0.2:1);

        case 'utilization'

            % Utilization is also bounded between zero and one.
            % A zero-based scale is retained.

            upperLimit = max(allUpper) * 1.15;

            upperLimit = min(1, max(upperLimit, 0.1));

            ylim(ax, [0 upperLimit]);

    end

    %% Legend

    lgd = legend(ax, ...
        'Location', 'best', ...
        'FontName', 'Arial', ...
        'FontSize', 11, ...
        'Box', 'on');

    lgd.Color = 'white';

    lgd.TextColor = 'black';

    lgd.EdgeColor = [0.3 0.3 0.3];

    %% Final figure formatting

    set(fig, 'Color', 'white');

    drawnow;

    %% Save high-resolution PNG

    pngFile = fullfile(outputFolder, ...
        [fileNames{m} '.png']);

    exportgraphics(fig, pngFile, ...
        'Resolution', 300, ...
        'BackgroundColor', 'white');

    %% Save editable MATLAB figure

    figFile = fullfile(outputFolder, ...
        [fileNames{m} '.fig']);

    savefig(fig, figFile);

    fprintf("Created: %s\n", fileNames{m});

    close(fig);

end

%% 6. EXPORT FIGURE DATA

summaryRows = {};

for m = 1:numMetrics

    field = metricFields{m};

    for s = 1:3

        for a = 1:numAlgorithms

            summaryRows(end+1,:) = { ...
                userCounts(s), ...
                algorithms(a), ...
                string(field), ...
                means.(field)(s,a), ...
                ciLower.(field)(s,a), ...
                ciUpper.(field)(s,a)};

        end

    end

end

figureData = cell2table(summaryRows, ...
    'VariableNames', { ...
    'Users', ...
    'Algorithm', ...
    'Metric', ...
    'Mean', ...
    'CI_Lower', ...
    'CI_Upper'});

writetable(figureData, ...
    fullfile(outputFolder, 'figure_data_200_runs.csv'));

%% 7. FINAL REPORT

fprintf("\n");
fprintf("====================================================\n");
fprintf("       FINAL THESIS FIGURES GENERATED\n");
fprintf("====================================================\n");

fprintf("Monte Carlo runs per scenario: %d\n", numRuns);

fprintf("Algorithms: %d\n", numAlgorithms);

fprintf("User scenarios: 20, 40, 60\n");

fprintf("Figures generated: %d\n", numMetrics);

fprintf("Image resolution: 300 DPI\n");

fprintf("Background: White\n");

fprintf("Editable MATLAB figures: Yes\n");

fprintf("Output folder: %s\n", outputFolder);

fprintf("====================================================\n");

fprintf("\nOriginal simulation results were not modified.\n");

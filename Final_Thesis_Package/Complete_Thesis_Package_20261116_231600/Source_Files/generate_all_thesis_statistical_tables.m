
%% ONE-CLICK THESIS STATISTICAL REPORT GENERATOR
% Uses existing combined 200-run simulation and validation files.
% Does NOT rerun simulations.
%
% Outputs:
%   1. One Excel workbook with six thesis tables
%   2. Six individual CSV files
%   3. A summary report in the MATLAB Command Window

clear; clc; close all;

fprintf('\n============================================\n');
fprintf(' THESIS STATISTICAL REPORT GENERATOR\n');
fprintf(' COMBINED 200-RUN RESULTS\n');
fprintf('============================================\n\n');

%% 1. Input files

resultsFile = "combined_200run_results.mat";
statsFile   = "combined_200run_statistical_validation.mat";

if ~isfile(resultsFile)
    error("Missing file: %s", resultsFile);
end

if ~isfile(statsFile)
    error("Missing file: %s", statsFile);
end

%% 2. Load saved results

R = load(resultsFile);
V = load(statsFile);

requiredResults = ["results20_combined", ...
                   "results40_combined", ...
                   "results60_combined"];

for k = 1:numel(requiredResults)
    if ~isfield(R, requiredResults(k))
        error("Missing variable %s in results file.", ...
            requiredResults(k));
    end
end

if ~isfield(V, "T") || ~istable(V.T)
    error("The validation file must contain a table named T.");
end

T = V.T;

fprintf("Simulation results loaded successfully.\n");
fprintf("Statistical validation results loaded successfully.\n");

%% 3. Define scenarios and algorithms

resultsByLoad = { ...
    R.results20_combined, ...
    R.results40_combined, ...
    R.results60_combined};

userCounts = [20 40 60];

algorithms = string(R.results20_combined.algorithms);
numAlgorithms = numel(algorithms);

metricFields = { ...
    'waiting', ...
    'turnaround', ...
    'fairness', ...
    'efficiencyFairness', ...
    'meanServiceEfficiency', ...
    'utilization'};

metricLabels = { ...
    'Waiting Time (ms)', ...
    'Turnaround Time (ms)', ...
    'Completion Fairness', ...
    'Service-Efficiency Fairness', ...
    'Mean Service Efficiency', ...
    'Resource Utilization'};

%% 4. Calculate descriptive statistics

descriptiveRows = {};

for s = 1:numel(userCounts)

    result = resultsByLoad{s};

    for m = 1:numel(metricFields)

        field = metricFields{m};
        raw = result.raw.(field);

        n = size(raw,1);
        tCritical = tinv(0.975,n-1);

        for a = 1:numAlgorithms

            x = raw(:,a);

            avg = mean(x);
            sd = std(x,0);
            margin = tCritical*sd/sqrt(n);

            descriptiveRows(end+1,:) = { ...
                userCounts(s), ...
                algorithms(a), ...
                string(metricLabels{m}), ...
                n, ...
                avg, ...
                sd, ...
                avg-margin, ...
                avg+margin};

        end
    end
end

Table41 = cell2table(descriptiveRows, ...
    'VariableNames', { ...
    'Users','Algorithm','Metric','Runs', ...
    'Mean','StandardDeviation', ...
    'CI_Lower','CI_Upper'});

%% 5. Validate statistical table structure

requiredColumns = { ...
    'Scenario', ...
    'Comparison', ...
    'Metric', ...
    'MeanDifference', ...
    'CI_Lower', ...
    'CI_Upper', ...
    'PairedT_P', ...
    'HolmT_P', ...
    'Wilcoxon_P', ...
    'HolmW_P', ...
    'CohensDz'};

for k = 1:numel(requiredColumns)
    if ~ismember(requiredColumns{k},T.Properties.VariableNames)
        error("Missing statistical column: %s", ...
            requiredColumns{k});
    end
end

%% 6. Separate comparison groups

comparisonText = string(T.Comparison);

% Priority against the three benchmark algorithms
isPriority = contains(comparisonText,"Priority minus") & ...
             ~contains(comparisonText,"Multilevel Queue");

% Multilevel Queue against the three benchmark algorithms
isMLQ = contains(comparisonText,"Multilevel Queue minus");

% Direct comparison between proposed algorithms
isDirect = contains(comparisonText,"Priority minus Multilevel Queue");

Table42 = T(isPriority,:);
Table43 = T(isMLQ,:);
Table44 = T(isDirect,:);

%% 7. Complete statistical comparison table

Table45 = T(:,requiredColumns);

% Add significance decisions after Holm correction
Table45.TTestSignificant = Table45.HolmT_P < 0.05;
Table45.WilcoxonSignificant = Table45.HolmW_P < 0.05;

%% 8. Effect-size table

Table46 = T(:,{ ...
    'Scenario', ...
    'Comparison', ...
    'Metric', ...
    'MeanDifference', ...
    'CI_Lower', ...
    'CI_Upper', ...
    'CohensDz'});

%% 9. Create output folder

outputFolder = "thesis_statistical_tables";

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

workbook = fullfile(outputFolder, ...
    "Complete_Thesis_Statistical_Tables.xlsx");

if isfile(workbook)
    delete(workbook);
end

%% 10. Export all six tables to Excel

writetable(Table41,workbook,'Sheet','Table_4_1_Descriptive');
writetable(Table42,workbook,'Sheet','Table_4_2_Priority');
writetable(Table43,workbook,'Sheet','Table_4_3_MLQ');
writetable(Table44,workbook,'Sheet','Table_4_4_Direct');
writetable(Table45,workbook,'Sheet','Table_4_5_Statistics');
writetable(Table46,workbook,'Sheet','Table_4_6_EffectSizes');

%% 11. Export individual CSV files

writetable(Table41,fullfile(outputFolder, ...
    "Table_4_1_Descriptive.csv"));

writetable(Table42,fullfile(outputFolder, ...
    "Table_4_2_Priority_Comparisons.csv"));

writetable(Table43,fullfile(outputFolder, ...
    "Table_4_3_MLQ_Comparisons.csv"));

writetable(Table44,fullfile(outputFolder, ...
    "Table_4_4_Priority_vs_MLQ.csv"));

writetable(Table45,fullfile(outputFolder, ...
    "Table_4_5_Statistical_Validation.csv"));

writetable(Table46,fullfile(outputFolder, ...
    "Table_4_6_Effect_Sizes.csv"));

%% 12. Print statistical summary

fprintf('\n============================================\n');
fprintf(' STATISTICAL VALIDATION SUMMARY\n');
fprintf('============================================\n');

for s = 1:numel(userCounts)

    scenarioLabel = string(userCounts(s)) + " Users";

    scenarioMask = string(Table45.Scenario) == scenarioLabel;

    if ~any(scenarioMask)
        scenarioMask = contains(string(Table45.Scenario), ...
            string(userCounts(s)));
    end

    X = Table45(scenarioMask,:);

    nT = sum(X.TTestSignificant);
    nW = sum(X.WilcoxonSignificant);

    agreement = sum(X.TTestSignificant == ...
                    X.WilcoxonSignificant);

    fprintf('\nSCENARIO: %d USERS\n',userCounts(s));
    fprintf('Total comparisons: %d\n',height(X));
    fprintf('Significant paired t-tests: %d\n',nT);
    fprintf('Significant Wilcoxon tests: %d\n',nW);
    fprintf('Test agreement: %d/%d\n', ...
        agreement,height(X));

end

%% 13. Print direct Priority vs MLQ results

fprintf('\n============================================\n');
fprintf(' PRIORITY VS MULTILEVEL QUEUE\n');
fprintf('============================================\n');

disp(Table44(:,{ ...
    'Scenario', ...
    'Metric', ...
    'MeanDifference', ...
    'HolmT_P', ...
    'HolmW_P', ...
    'CohensDz'}));

%% 14. Final completion message

fprintf('\n============================================\n');
fprintf(' ALL THESIS TABLES GENERATED SUCCESSFULLY\n');
fprintf('============================================\n');

fprintf('Excel workbook:\n%s\n',workbook);

fprintf('\nOutput folder:\n%s\n',outputFolder);

fprintf('\nTables generated: 6\n');
fprintf('CSV files generated: 6\n');

fprintf('\nNo simulations were rerun.\n');
fprintf('No original results were modified.\n');

fprintf('\n============================================\n');

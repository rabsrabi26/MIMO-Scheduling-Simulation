
%% COMBINE TWO EXPERIMENTS AND VALIDATE 200 RUNS
% Combines the original and independent 100-run experiments.
% Does not rerun simulations or modify the original result files.

clear; clc;

fprintf('\n============================================\n');
fprintf(' COMBINING FINAL AND INDEPENDENT EXPERIMENTS\n');
fprintf('============================================\n');

%% 1. Load both datasets

load("final_thesis_results.mat");
load("independent_seed_results.mat");

finalResults = {results20_final, results40_final, results60_final};
indResults = {results20_independent, ...
              results40_independent, results60_independent};

finalCfg = {cfg20, cfg40, cfg60};
indCfg = {cfg20_independent, ...
          cfg40_independent, cfg60_independent};

scenarioNames = ["20 Users", "40 Users", "60 Users"];

metrics = ["waiting", "turnaround", "fairness", ...
           "efficiencyFairness", ...
           "meanServiceEfficiency", "utilization"];

%% 2. Verify that the experimental configurations match

for s = 1:3

    assert(finalCfg{s}.numUsers == indCfg{s}.numUsers, ...
        'User-count mismatch.');

    assert(finalCfg{s}.numAntennas == indCfg{s}.numAntennas, ...
        'Antenna-count mismatch.');

    assert(finalCfg{s}.alpha == indCfg{s}.alpha, ...
        'Alpha mismatch.');

    assert(finalCfg{s}.beta == indCfg{s}.beta, ...
        'Beta mismatch.');

    assert(isequal(string(finalCfg{s}.algorithms), ...
                   string(indCfg{s}.algorithms)), ...
        'Algorithm-order mismatch.');

    assert(finalResults{s}.numRuns == 100 && ...
           indResults{s}.numRuns == 100, ...
        'Expected exactly 100 runs in each dataset.');

end

algorithms = string(cfg20.algorithms);

fprintf('\nConfiguration checks passed.\n');
fprintf('Algorithms: %s\n', strjoin(algorithms, ', '));
fprintf('Runs per scenario: 200\n');
fprintf('Antennas: %d\n', cfg20.numAntennas);
fprintf('Alpha: %.2f | Beta: %.2f\n', cfg20.alpha, cfg20.beta);

%% 3. Combine raw observations

combined = cell(1,3);

for s = 1:3

    combined{s}.algorithms = algorithms;
    combined{s}.numRuns = 200;
    combined{s}.numUsers = finalResults{s}.numUsers;
    combined{s}.numAntennas = finalResults{s}.numAntennas;

    for m = metrics

        originalData = finalResults{s}.raw.(m);
        independentData = indResults{s}.raw.(m);

        assert(isequal(size(originalData), [100, numel(algorithms)]), ...
            'Unexpected original raw-data dimensions.');

        assert(isequal(size(independentData), [100, numel(algorithms)]), ...
            'Unexpected independent raw-data dimensions.');

        combined{s}.raw.(m) = ...
            [originalData; independentData];

        x = combined{s}.raw.(m);

        combined{s}.summary.(m).mean = mean(x,1);
        combined{s}.summary.(m).std = std(x,0,1);
        combined{s}.summary.(m).ci95 = ...
            1.96 * std(x,0,1) / sqrt(200);

    end

    fprintf('Combined %s: 200 runs completed.\n', scenarioNames(s));

end

results20_combined = combined{1};
results40_combined = combined{2};
results60_combined = combined{3};

%% 4. Create descriptive statistics table

summaryRows = cell(0,8);

for s = 1:3

    for a = 1:numel(algorithms)

        for m = metrics

            st = combined{s}.summary.(m);

            mu = st.mean(a);
            sd = st.std(a);
            halfCI = st.ci95(a);

            summaryRows(end+1,:) = { ...
                scenarioNames(s), algorithms(a), m, ...
                200, mu, sd, mu-halfCI, mu+halfCI};

        end
    end
end

summaryTable = cell2table(summaryRows, ...
    'VariableNames', {'Scenario','Algorithm','Metric','Runs', ...
    'Mean','StandardDeviation','CI95_Lower','CI95_Upper'});

%% 5. Define all pairwise comparisons

% Positive difference means the first algorithm has a higher value.

comparisonNames = [ ...
    "Priority minus Round Robin"
    "Priority minus Proportional Fair"
    "Priority minus Max C/I"
    "Multilevel Queue minus Round Robin"
    "Multilevel Queue minus Proportional Fair"
    "Multilevel Queue minus Max C/I"
    "Priority minus Multilevel Queue"];

firstIndex  = [1 1 1 2 2 2 1];
secondIndex = [3 4 5 3 4 5 2];

numComparisons = 42;
numScenarios = 3;
totalRows = numComparisons * numScenarios;

%% 6. Preallocate statistical results table

T = table( ...
    strings(totalRows,1), ...
    strings(totalRows,1), ...
    strings(totalRows,1), ...
    zeros(totalRows,1), ...
    zeros(totalRows,1), ...
    zeros(totalRows,1), ...
    zeros(totalRows,1), ...
    zeros(totalRows,1), ...
    zeros(totalRows,1), ...
    zeros(totalRows,1), ...
    false(totalRows,1), ...
    zeros(totalRows,1), ...
    zeros(totalRows,1), ...
    false(totalRows,1), ...
    zeros(totalRows,1), ...
    'VariableNames', { ...
    'Scenario','Comparison','Metric','N', ...
    'MeanDifference','MedianDifference', ...
    'CI_Lower','CI_Upper','PairedT_P','HolmT_P', ...
    'T_Significant','Wilcoxon_P','HolmW_P', ...
    'W_Significant','CohensDz'});

%% 7. Run paired statistical comparisons

for s = 1:3

    fprintf('\nAnalyzing %s...\n', scenarioNames(s));

    scenarioRows = (s-1)*numComparisons + ...
                   (1:numComparisons);

    row = scenarioRows(1);

    pT = zeros(numComparisons,1);
    pW = zeros(numComparisons,1);

    for c = 1:7

        p = firstIndex(c);
        b = secondIndex(c);

        for m = 1:numel(metrics)

            metric = metrics(m);

            x = combined{s}.raw.(metric);

            d = x(:,p) - x(:,b);

            % Treat numerical zero as zero.
            if all(abs(d) <= 1e-10)

                meanDiff = 0;
                medianDiff = 0;
                ci = [0 0];
                pt = 1;
                pw = 1;
                dz = 0;

            else

                meanDiff = mean(d);
                medianDiff = median(d);

                [~, pt, ci] = ttest(d);

                pw = signrank(d);

                sdDiff = std(d,0);

                if sdDiff > eps
                    dz = meanDiff / sdDiff;
                else
                    dz = sign(meanDiff) * Inf;
                end

            end

            T.Scenario(row) = scenarioNames(s);
            T.Comparison(row) = comparisonNames(c);
            T.Metric(row) = metric;
            T.N(row) = numel(d);

            T.MeanDifference(row) = meanDiff;
            T.MedianDifference(row) = medianDiff;
            T.CI_Lower(row) = ci(1);
            T.CI_Upper(row) = ci(2);

            T.PairedT_P(row) = pt;
            T.Wilcoxon_P(row) = pw;
            T.CohensDz(row) = dz;

            pT((c-1)*numel(metrics)+m) = pt;
            pW((c-1)*numel(metrics)+m) = pw;

            row = row + 1;

        end
    end

    %% Holm correction across all 42 comparisons in this scenario

    holmT = holm_adjust(pT);
    holmW = holm_adjust(pW);

    T.HolmT_P(scenarioRows) = holmT;
    T.HolmW_P(scenarioRows) = holmW;

    T.T_Significant(scenarioRows) = holmT < 0.05;
    T.W_Significant(scenarioRows) = holmW < 0.05;

    nT = sum(holmT < 0.05);
    nW = sum(holmW < 0.05);

    agreement = sum((holmT < 0.05) == (holmW < 0.05));

    fprintf('Paired t-test significant: %d/42\n', nT);
    fprintf('Wilcoxon significant: %d/42\n', nW);
    fprintf('Test agreement: %d/42\n', agreement);

end

%% 8. Save combined results and statistical validation

save("combined_200run_results.mat", ...
    "results20_combined", ...
    "results40_combined", ...
    "results60_combined", ...
    "summaryTable");

save("combined_200run_statistical_validation.mat", "T");

writetable(summaryTable, "combined_200run_summary.csv");
writetable(T, "combined_200run_statistical_validation.csv");

%% 9. Display summary

fprintf('\n============================================\n');
fprintf(' COMBINED 200-RUN EXPERIMENT SUMMARY\n');
fprintf('============================================\n');

disp(summaryTable);

fprintf('\n============================================\n');
fprintf(' STATISTICAL VALIDATION COMPLETED\n');
fprintf('============================================\n');

fprintf('Combined dataset saved:\n');
fprintf('  combined_200run_results.mat\n');
fprintf('  combined_200run_summary.csv\n');

fprintf('\nStatistical validation saved:\n');
fprintf('  combined_200run_statistical_validation.mat\n');
fprintf('  combined_200run_statistical_validation.csv\n');

%% 10. Holm-Bonferroni adjustment function

function adjusted = holm_adjust(p)

    p = p(:);

    [sortedP, order] = sort(p);

    n = numel(p);

    adjustedSorted = (n - (1:n)' + 1) .* sortedP;

    adjustedSorted = cummax(adjustedSorted);
    adjustedSorted = min(adjustedSorted,1);

    adjusted = zeros(size(p));
    adjusted(order) = adjustedSorted;

end


% COMPARE_FINAL_PRIORITY_VS_MLQ
% Direct paired comparison of Priority and Multilevel Queue.
% Uses final experiments: 20, 40 and 60 users.
% Includes numerical tolerance, paired t-tests, Wilcoxon tests,
% Holm correction, confidence intervals and Cohen's dz.

clc;
clear;

fprintf("\n========================================\n");
fprintf(" FINAL PRIORITY VS MLQ COMPARISON\n");
fprintf("========================================\n");

%% Load final results

load("final_thesis_results.mat");

datasets = {results20_final, results40_final, results60_final};
scenarioNames = ["20 Users", "40 Users", "60 Users"];

metricNames = ["waiting", "turnaround", "fairness", ...
    "efficiencyFairness", "meanServiceEfficiency", "utilization"];

priorityIndex = 1;
mlqIndex = 2;

% Numerical tolerance for floating-point noise.
tolerance = 1e-10;

allComparisons = table();

%% Process each scenario

for s = 1:numel(datasets)

    results = datasets{s};

    fprintf("\n========================================\n");
    fprintf(" SCENARIO: %s\n", scenarioNames(s));
    fprintf("========================================\n");

    nMetrics = numel(metricNames);

    meanDiff = zeros(nMetrics,1);
    medianDiff = zeros(nMetrics,1);
    ciLower = zeros(nMetrics,1);
    ciUpper = zeros(nMetrics,1);
    pT = ones(nMetrics,1);
    pW = ones(nMetrics,1);
    cohensDz = zeros(nMetrics,1);

    for m = 1:nMetrics

        metric = metricNames(m);
        x = results.raw.(char(metric));

        % Positive difference means Priority has a higher value.
        d = x(:,priorityIndex) - x(:,mlqIndex);

        % Remove floating-point noise.
        d(abs(d) < tolerance) = 0;

        meanDiff(m) = mean(d);
        medianDiff(m) = median(d);

        if all(d == 0)
            ciLower(m) = 0;
            ciUpper(m) = 0;
            pT(m) = 1;
            pW(m) = 1;
            cohensDz(m) = 0;
        else
            [~, pT(m), ci] = ttest(d);

            ciLower(m) = ci(1);
            ciUpper(m) = ci(2);

            % Wilcoxon signed-rank test.
            nonzeroD = d(d ~= 0);
            pW(m) = signrank(nonzeroD);

            sdDiff = std(d,0);

            if sdDiff > 0
                cohensDz(m) = mean(d)/sdDiff;
            end
        end
    end

    %% Holm correction across six metrics

    n = nMetrics;

    [sortedT, orderT] = sort(pT);
    [sortedW, orderW] = sort(pW);

    adjT = cummax(sortedT .* (n-(1:n)' + 1));
    adjW = cummax(sortedW .* (n-(1:n)' + 1));

    adjT = min(adjT,1);
    adjW = min(adjW,1);

    pHolmT = ones(n,1);
    pHolmW = ones(n,1);

    pHolmT(orderT) = adjT;
    pHolmW(orderW) = adjW;

    significantT = pHolmT < 0.05;
    significantW = pHolmW < 0.05;

    %% Build table

    T = table( ...
        repmat(scenarioNames(s),nMetrics,1), ...
        metricNames', ...
        meanDiff, medianDiff, ...
        ciLower, ciUpper, ...
        pT, pHolmT, significantT, ...
        pW, pHolmW, significantW, ...
        cohensDz, ...
        'VariableNames', { ...
        'Scenario','Metric', ...
        'MeanDifference','MedianDifference', ...
        'CI_Lower','CI_Upper', ...
        'PairedT_P','HolmT_P','T_Significant', ...
        'Wilcoxon_P','HolmW_P','W_Significant', ...
        'CohensDz'});

    disp(T);

    fprintf("\nPaired t-test significant: %d/%d\n", ...
        sum(significantT),n);

    fprintf("Wilcoxon significant: %d/%d\n", ...
        sum(significantW),n);

    fprintf("Test agreement: %d/%d\n", ...
        sum(significantT == significantW),n);

    allComparisons = [allComparisons; T];

end

%% Save results

save("final_priority_vs_mlq_validation.mat", ...
    "allComparisons","tolerance");

writetable(allComparisons, ...
    "final_priority_vs_mlq_validation.csv");

fprintf("\n========================================\n");
fprintf(" PRIORITY VS MLQ VALIDATION COMPLETED\n");
fprintf("========================================\n");

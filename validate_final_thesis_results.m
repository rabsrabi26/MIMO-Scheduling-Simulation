% VALIDATE_FINAL_THESIS_RESULTS
% Statistical validation of final alpha=beta=0.5 experiments.
% Paired t-tests, Wilcoxon tests, Holm correction and effect sizes.

clc;
fprintf("\n========================================\nFINAL THESIS STATISTICAL VALIDATION\n========================================\n");
load("final_thesis_results.mat");

datasets={results20_final,results40_final,results60_final};
scenarioNames=["20 Users","40 Users","60 Users"];
metricNames=["waiting","turnaround","fairness","efficiencyFairness", ...
    "meanServiceEfficiency","utilization"];
proposedIndices=[1 2]; benchmarkIndices=[3 4 5];
allComparisons=table();

for s=1:numel(datasets)
    results=datasets{s}; algorithms=results.algorithms;
    fprintf("\n========================================\nSCENARIO: %s\n========================================\n",scenarioNames(s));
    comparisonCount=numel(proposedIndices)*numel(benchmarkIndices)*numel(metricNames);
    proposedNames=strings(comparisonCount,1);
    benchmarkNames=strings(comparisonCount,1);
    metricColumn=strings(comparisonCount,1);
    meanDiff=zeros(comparisonCount,1); ciLower=zeros(comparisonCount,1);
    ciUpper=zeros(comparisonCount,1); pT=zeros(comparisonCount,1);
    pW=zeros(comparisonCount,1); cohensDz=zeros(comparisonCount,1);
    row=0;
    for m=1:numel(metricNames)
        metric=metricNames(m); x=results.raw.(char(metric));
        for p=proposedIndices
            for b=benchmarkIndices
                row=row+1; d=x(:,p)-x(:,b);
                [~,pT(row),ci]=ttest(d); pW(row)=signrank(d);
                meanDiff(row)=mean(d); ciLower(row)=ci(1); ciUpper(row)=ci(2);
                sdDiff=std(d,0);
                if sdDiff>0, cohensDz(row)=mean(d)/sdDiff; end
                proposedNames(row)=string(algorithms(p));
                benchmarkNames(row)=string(algorithms(b));
                metricColumn(row)=metric;
            end
        end
    end
    pHolmT=zeros(size(pT)); pHolmW=zeros(size(pW));
    [sortedT,orderT]=sort(pT); [sortedW,orderW]=sort(pW);
    n=numel(pT);
    adjT=cummax(sortedT.*(n-(1:n)'+1));
    adjW=cummax(sortedW.*(n-(1:n)'+1));
    adjT=min(adjT,1); adjW=min(adjW,1);
    pHolmT(orderT)=adjT; pHolmW(orderW)=adjW;
    significantT=pHolmT<0.05; significantW=pHolmW<0.05;
    T=table(repmat(scenarioNames(s),comparisonCount,1),proposedNames, ...
        benchmarkNames,metricColumn,meanDiff,ciLower,ciUpper,pT,pHolmT, ...
        significantT,pW,pHolmW,significantW,cohensDz, ...
        'VariableNames',{'Scenario','ProposedAlgorithm','Benchmark','Metric', ...
        'MeanDifference','CI_Lower','CI_Upper','PairedT_P','HolmT_P', ...
        'T_Significant','Wilcoxon_P','HolmW_P','W_Significant','CohensDz'});
    disp(T);
    fprintf("\nPaired t-test significant: %d/%d\n",sum(significantT),comparisonCount);
    fprintf("Wilcoxon significant: %d/%d\n",sum(significantW),comparisonCount);
    fprintf("Test decision agreement: %d/%d\n",sum(significantT==significantW),comparisonCount);
    allComparisons=[allComparisons;T];
end
save("final_thesis_statistical_validation.mat","allComparisons");
writetable(allComparisons,"final_thesis_statistical_validation.csv");
fprintf("\n========================================\nFINAL STATISTICAL VALIDATION COMPLETED\n========================================\n");

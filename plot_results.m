function plot_results(results,cfg,filename)
%PLOT_RESULTS Plot means with 95% normal-approximation confidence intervals.
A=cellstr(results.algorithms);
figure("Color","w","Position",[100 100 1200 800]);
names={"waiting","turnaround","fairness","utilization"};
titles={"Mean waiting time","Mean turnaround time","Jain fairness","Resource utilization"};
ylabs={"ms","ms","Index","Fraction"};
for k=1:4
    subplot(2,2,k);
    m=results.summary.(names{k}).mean;
    ci=results.summary.(names{k}).ci95;
    bar(m); hold on;
    errorbar(1:numel(m),m,ci,"k.","LineWidth",1.2);
    set(gca,"XTick",1:numel(m),"XTickLabel",A);
    xtickangle(25); title(titles{k}); ylabel(ylabs{k}); grid on;
    if k>=3, ylim([0 1]); end
end
sgtitle(sprintf("Scheduling comparison: K=%d, M=%d, runs=%d", ...
    cfg.numUsers,cfg.numAntennas,cfg.numRuns));
exportgraphics(gcf,filename,"Resolution",180);
end

function plot_results(avg_await, ci_await, avg_att, ci_att, avg_jfi, ci_jfi, avg_util, ci_util, algorithm_names)
    % PLOT_RESULTS Create visualization of simulation results
    
    % Create figure
    figure('Position', [100, 100, 1200, 800]);
    
    % Plot Average Waiting Time
    subplot(2, 2, 1);
    bar(avg_await);
    hold on;
    errorbar(1:length(avg_await), avg_await, ci_await, 'k.', 'LineWidth', 1.5);
    title('Average Waiting Time');
    ylabel('Time (ms)');
    set(gca, 'XTickLabel', algorithm_names);
    xtickangle(45);
    grid on;
    
    % Plot Average Turnaround Time
    subplot(2, 2, 2);
    bar(avg_att);
    hold on;
    errorbar(1:length(avg_att), avg_att, ci_att, 'k.', 'LineWidth', 1.5);
    title('Average Turnaround Time');
    ylabel('Time (ms)');
    set(gca, 'XTickLabel', algorithm_names);
    xtickangle(45);
    grid on;
    
    % Plot Jain's Fairness Index
    subplot(2, 2, 3);
    bar(avg_jfi);
    hold on;
    errorbar(1:length(avg_jfi), avg_jfi, ci_jfi, 'k.', 'LineWidth', 1.5);
    title('Jain''s Fairness Index');
    ylabel('Index');
    ylim([0, 1]);
    set(gca, 'XTickLabel', algorithm_names);
    xtickangle(45);
    grid on;
    
    % Plot Resource Utilization
    subplot(2, 2, 4);
    bar(avg_util);
    hold on;
    errorbar(1:length(avg_util), avg_util, ci_util, 'k.', 'LineWidth', 1.5);
    title('Resource Utilization');
    ylabel('Utilization');
    ylim([0, 1]);
    set(gca, 'XTickLabel', algorithm_names);
    xtickangle(45);
    grid on;
    
    % Add overall title
    sgtitle('Performance Comparison of Scheduling Algorithms', 'FontSize', 16, 'FontWeight', 'bold');
    
    % Save figure
    saveas(gcf, 'scheduling_results.png');
end
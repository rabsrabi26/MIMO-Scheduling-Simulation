function ci = calculate_ci(data)
    % CALCULATE_CI Calculate 95% confidence intervals.
    
    n = size(data, 1);  % Number of samples (simulation runs)
    sem = std(data) / sqrt(n);  % Standard error of the mean
    ci = 1.96 * sem;   % 95% confidence interval (z-score = 1.96)
end
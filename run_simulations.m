%% Batch Simulation Runner
% This script runs multiple simulations with different parameters

clear all; close all; clc;

% Parameter ranges to test
user_counts = [10, 20, 30, 40];
antenna_counts = [4, 8, 16, 32, 64];
simulationRuns = 10;  % Fewer runs for batch simulation

% Other fixed parameters
cellRadius = 500;
alpha = 0.7;
beta = 0.3;
queue_ranges = [0, 125; 125, 250; 250, 375; 375, 500];

algorithm_names = {'Priority', 'Multilevel Queue', 'Round Robin', 'Proportional Fair', 'Max C/I'};

% Initialize results structure
results = struct();

fprintf('Starting batch simulations...\n');

for k_idx = 1:length(user_counts)
    numUsers = user_counts(k_idx);
    
    for m_idx = 1:length(antenna_counts)
        numAntennas = antenna_counts(m_idx);
        
        fprintf('Running simulation for K=%d, M=%d...\n', numUsers, numAntennas);
        
        % Initialize results for this configuration
        await_results = zeros(simulationRuns, 5);
        att_results = zeros(simulationRuns, 5);
        jfi_results = zeros(simulationRuns, 5);
        util_results = zeros(simulationRuns, 5);
        
        % Run multiple simulations for this configuration
        for run = 1:simulationRuns
            % 1. Generate User Parameters
            [userLocations, userDistances] = generateUsers(numUsers, cellRadius);
            [serviceTypes, arrivalTimes, burstTimes] = generateTraffic(numUsers);
            
            % 2. Calculate Channel (Path Loss)
            pathLoss = calculatePathLoss(userDistances, cellRadius);
            
            % 3. Create user structure array
            users = struct();
            for i = 1:numUsers
                users(i).id = i;
                users(i).distance = userDistances(i);
                users(i).service_type = serviceTypes(i);
                users(i).arrival_time = arrivalTimes(i);
                users(i).burst_time = burstTimes(i);
                users(i).path_loss = pathLoss(i);
            end
            
            % 4. Run Each Scheduler
            [awt_priority, att_priority, jfi_priority, util_priority] = scheduler_priority(users, numAntennas, alpha, beta);
            [awt_multilevel, att_multilevel, jfi_multilevel, util_multilevel] = scheduler_multilevel(users, numAntennas, queue_ranges, alpha, beta);
            [awt_rr, att_rr, jfi_rr, util_rr] = scheduler_rr(users, numAntennas);
            [awt_pf, att_pf, jfi_pf, util_pf] = scheduler_pf(users, numAntennas);
            [awt_maxci, att_maxci, jfi_maxci, util_maxci] = scheduler_maxci(users, numAntennas);
            
            % 5. Store results for this run
            await_results(run, :) = [awt_priority, awt_multilevel, awt_rr, awt_pf, awt_maxci];
            att_results(run, :) = [att_priority, att_multilevel, att_rr, att_pf, att_maxci];
            jfi_results(run, :) = [jfi_priority, jfi_multilevel, jfi_rr, jfi_pf, jfi_maxci];
            util_results(run, :) = [util_priority, util_multilevel, util_rr, util_pf, util_maxci];
        end
        
        % Calculate averages for this configuration
        results(k_idx, m_idx).K = numUsers;
        results(k_idx, m_idx).M = numAntennas;
        results(k_idx, m_idx).avg_await = mean(await_results, 1);
        results(k_idx, m_idx).avg_att = mean(att_results, 1);
        results(k_idx, m_idx).avg_jfi = mean(jfi_results, 1);
        results(k_idx, m_idx).avg_util = mean(util_results, 1);
    end
end

fprintf('Batch simulations completed!\n');

% Save results to file
save('batch_simulation_results.mat', 'results', 'user_counts', 'antenna_counts', 'algorithm_names');

% Plot results for different configurations
figure('Position', [100, 100, 1200, 800]);

% Plot for fixed M=16, varying K
subplot(2, 2, 1);
hold on;
colors = ['r', 'g', 'b', 'c', 'm'];
for algo = 1:5
    data = zeros(1, length(user_counts));
    for k_idx = 1:length(user_counts)
        % Find the index where M=16
        m_idx = find(antenna_counts == 16, 1);
        data(k_idx) = results(k_idx, m_idx).avg_await(algo);
    end
    plot(user_counts, data, ['-o' colors(algo)], 'LineWidth', 2, 'DisplayName', algorithm_names{algo});
end
title('AWT vs Number of Users (M=16)');
xlabel('Number of Users (K)');
ylabel('Average Waiting Time (ms)');
legend('show');
grid on;

% Plot for fixed K=20, varying M
subplot(2, 2, 2);
hold on;
for algo = 1:5
    data = zeros(1, length(antenna_counts));
    for m_idx = 1:length(antenna_counts)
        % Find the index where K=20
        k_idx = find(user_counts == 20, 1);
        data(m_idx) = results(k_idx, m_idx).avg_await(algo);
    end
    plot(antenna_counts, data, ['-o' colors(algo)], 'LineWidth', 2, 'DisplayName', algorithm_names{algo});
end
title('AWT vs Number of Antennas (K=20)');
xlabel('Number of Antennas (M)');
ylabel('Average Waiting Time (ms)');
legend('show');
grid on;

% Plot fairness for fixed M=16, varying K
subplot(2, 2, 3);
hold on;
for algo = 1:5
    data = zeros(1, length(user_counts));
    for k_idx = 1:length(user_counts)
        % Find the index where M=16
        m_idx = find(antenna_counts == 16, 1);
        data(k_idx) = results(k_idx, m_idx).avg_jfi(algo);
    end
    plot(user_counts, data, ['-o' colors(algo)], 'LineWidth', 2, 'DisplayName', algorithm_names{algo});
end
title('JFI vs Number of Users (M=16)');
xlabel('Number of Users (K)');
ylabel('Jain''s Fairness Index');
legend('show');
grid on;

% Plot utilization for fixed K=20, varying M
subplot(2, 2, 4);
hold on;
for algo = 1:5
    data = zeros(1, length(antenna_counts));
    for m_idx = 1:length(antenna_counts)
        % Find the index where K=20
        k_idx = find(user_counts == 20, 1);
        data(m_idx) = results(k_idx, m_idx).avg_util(algo);
    end
    plot(antenna_counts, data, ['-o' colors(algo)], 'LineWidth', 2, 'DisplayName', algorithm_names{algo});
end
title('Utilization vs Number of Antennas (K=20)');
xlabel('Number of Antennas (M)');
ylabel('Resource Utilization');
legend('show');
grid on;

sgtitle('Batch Simulation Results', 'FontSize', 16, 'FontWeight', 'bold');

% Save figure
saveas(gcf, 'batch_simulation_results.png');
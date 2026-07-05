%% Results for Varying Number of Users
% This script runs simulations with different numbers of users (K)

clear all; close all; clc;

% Simulation parameters
user_counts = [10, 20, 30, 40];  % Different user counts to test
numAntennas = 16;                 % Fixed number of antennas
cellRadius = 500;                 % Cell radius in meters
simulationRuns = 20;              % Number of simulation runs per configuration

% Priority scheduler parameters
alpha = 0.7;           % Weight for distance component
beta = 0.3;            % Weight for service type component

% Multilevel queue parameters
queue_ranges = [0, 125; 125, 250; 250, 375; 375, 500]; % Distance ranges for queues

algorithm_names = {'Priority', 'Multilevel Queue', 'Round Robin', 'Proportional Fair', 'Max C/I'};

% Initialize results storage
await_results = zeros(length(user_counts), 5);
att_results = zeros(length(user_counts), 5);
jfi_results = zeros(length(user_counts), 5);
util_results = zeros(length(user_counts), 5);

fprintf('Running simulations for varying number of users...\n');
progress = waitbar(0, 'Starting simulations...');

for k_idx = 1:length(user_counts)
    numUsers = user_counts(k_idx);
    waitbar(k_idx/length(user_counts), progress, sprintf('Testing K=%d users', numUsers));
    
    % Initialize temporary storage for this configuration
    await_temp = zeros(simulationRuns, 5);
    att_temp = zeros(simulationRuns, 5);
    jfi_temp = zeros(simulationRuns, 5);
    util_temp = zeros(simulationRuns, 5);
    
    for run = 1:simulationRuns
        % Generate User Parameters
        [userLocations, userDistances] = generateUsers(numUsers, cellRadius);
        [serviceTypes, arrivalTimes, burstTimes] = generateTraffic(numUsers);
        
        % Calculate Channel (Path Loss)
        pathLoss = calculatePathLoss(userDistances, cellRadius);
        
        % Create user structure array
        users = struct();
        for i = 1:numUsers
            users(i).id = i;
            users(i).distance = userDistances(i);
            users(i).service_type = serviceTypes(i);
            users(i).arrival_time = arrivalTimes(i);
            users(i).burst_time = burstTimes(i);
            users(i).path_loss = pathLoss(i);
        end
        
        % Run Each Scheduler
        [awt_priority, att_priority, jfi_priority, util_priority] = scheduler_priority(users, numAntennas, alpha, beta);
        [awt_multilevel, att_multilevel, jfi_multilevel, util_multilevel] = scheduler_multilevel(users, numAntennas, queue_ranges, alpha, beta);
        [awt_rr, att_rr, jfi_rr, util_rr] = scheduler_rr(users, numAntennas);
        [awt_pf, att_pf, jfi_pf, util_pf] = scheduler_pf(users, numAntennas);
        [awt_maxci, att_maxci, jfi_maxci, util_maxci] = scheduler_maxci(users, numAntennas);
        
        % Store results for this run
        await_temp(run, :) = [awt_priority, awt_multilevel, awt_rr, awt_pf, awt_maxci];
        att_temp(run, :) = [att_priority, att_multilevel, att_rr, att_pf, att_maxci];
        jfi_temp(run, :) = [jfi_priority, jfi_multilevel, jfi_rr, jfi_pf, jfi_maxci];
        util_temp(run, :) = [util_priority, util_multilevel, util_rr, util_pf, util_maxci];
    end
    
    % Calculate averages for this configuration
    await_results(k_idx, :) = mean(await_temp, 1);
    att_results(k_idx, :) = mean(att_temp, 1);
    jfi_results(k_idx, :) = mean(jfi_temp, 1);
    util_results(k_idx, :) = mean(util_temp, 1);
end

close(progress);

% Plot results
figure('Position', [100, 100, 1200, 800]);

% Plot Average Waiting Time
subplot(2, 2, 1);
hold on;
colors = ['r', 'g', 'b', 'c', 'm'];
for algo = 1:5
    plot(user_counts, await_results(:, algo), ['-o' colors(algo)], 'LineWidth', 2, 'DisplayName', algorithm_names{algo});
end
title('Average Waiting Time vs Number of Users');
xlabel('Number of Users (K)');
ylabel('Average Waiting Time (ms)');
legend('show');
grid on;

% Plot Average Turnaround Time
subplot(2, 2, 2);
hold on;
for algo = 1:5
    plot(user_counts, att_results(:, algo), ['-o' colors(algo)], 'LineWidth', 2, 'DisplayName', algorithm_names{algo});
end
title('Average Turnaround Time vs Number of Users');
xlabel('Number of Users (K)');
ylabel('Average Turnaround Time (ms)');
legend('show');
grid on;

% Plot Jain's Fairness Index
subplot(2, 2, 3);
hold on;
for algo = 1:5
    plot(user_counts, jfi_results(:, algo), ['-o' colors(algo)], 'LineWidth', 2, 'DisplayName', algorithm_names{algo});
end
title('Jain''s Fairness Index vs Number of Users');
xlabel('Number of Users (K)');
ylabel('Jain''s Fairness Index');
legend('show');
grid on;

% Plot Resource Utilization
subplot(2, 2, 4);
hold on;
for algo = 1:5
    plot(user_counts, util_results(:, algo), ['-o' colors(algo)], 'LineWidth', 2, 'DisplayName', algorithm_names{algo});
end
title('Resource Utilization vs Number of Users');
xlabel('Number of Users (K)');
ylabel('Resource Utilization');
legend('show');
grid on;

sgtitle('Impact of Number of Users on Scheduling Performance (M=16)', 'FontSize', 16, 'FontWeight', 'bold');

% Save results and figure
save('vary_users_results.mat', 'user_counts', 'await_results', 'att_results', 'jfi_results', 'util_results');
saveas(gcf, 'vary_users_results.png');

fprintf('Simulation completed! Results saved to vary_users_results.mat and vary_users_results.png\n');
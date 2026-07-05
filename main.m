%% Main Simulation for Massive MIMO Scheduling Algorithms
% This script runs the simulation of various scheduling algorithms for
% massive MIMO systems and generates performance results.

clear all; close all; clc;

%% Simulation Parameters
simulationRuns = 50;   % Number of independent simulation runs
numUsers = 20;         % Number of users (K)
numAntennas = 16;      % Number of antennas at BS (M)
cellRadius = 500;      % Cell radius in meters

% Priority scheduler parameters
alpha = 0.7;           % Weight for distance component
beta = 0.3;            % Weight for service type component

% Multilevel queue parameters
queue_ranges = [0, 125; 125, 250; 250, 375; 375, 500]; % Distance ranges for queues

%% Initialize results storage
results = struct();
results.awt = zeros(simulationRuns, 5);  % Average Waiting Time for 5 algorithms
results.att = zeros(simulationRuns, 5);  % Average Turnaround Time
results.jfi = zeros(simulationRuns, 5);  % Jain's Fairness Index
results.util = zeros(simulationRuns, 5); % Resource Utilization

algorithm_names = {'Priority', 'Multilevel Queue', 'Round Robin', 'Proportional Fair', 'Max C/I'};

%% Main simulation loop
fprintf('Starting simulation with %d runs...\n', simulationRuns);
progress = waitbar(0, 'Starting simulations...');

for run = 1:simulationRuns
    % Update progress bar
    waitbar(run/simulationRuns, progress, sprintf('Run %d of %d', run, simulationRuns));
    
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
    results.awt(run, :) = [awt_priority, awt_multilevel, awt_rr, awt_pf, awt_maxci];
    results.att(run, :) = [att_priority, att_multilevel, att_rr, att_pf, att_maxci];
    results.jfi(run, :) = [jfi_priority, jfi_multilevel, jfi_rr, jfi_pf, jfi_maxci];
    results.util(run, :) = [util_priority, util_multilevel, util_rr, util_pf, util_maxci];
end

close(progress);

%% Calculate averages and confidence intervals
avg_await = mean(results.awt, 1);
ci_await = calculate_ci(results.awt);

avg_att = mean(results.att, 1);
ci_att = calculate_ci(results.att);

avg_jfi = mean(results.jfi, 1);
ci_jfi = calculate_ci(results.jfi);

avg_util = mean(results.util, 1);
ci_util = calculate_ci(results.util);

%% Display results
fprintf('\n=== Simulation Results ===\n');
fprintf('Configuration: K=%d, M=%d, Cell Radius=%dm, %d runs\n\n', numUsers, numAntennas, cellRadius, simulationRuns);

fprintf('Algorithm\t\tAWT (ms)\tATT (ms)\tJFI\t\tUtilization\n');
fprintf('---------\t\t--------\t--------\t---\t\t-----------\n');
for i = 1:5
    fprintf('%-16s\t%.2f ± %.2f\t%.2f ± %.2f\t%.2f ± %.2f\t%.2f ± %.2f\n', ...
            algorithm_names{i}, avg_await(i), ci_await(i), avg_att(i), ci_att(i), ...
            avg_jfi(i), ci_jfi(i), avg_util(i), ci_util(i));
end

%% Plot results
plot_results(avg_await, ci_await, avg_att, ci_att, avg_jfi, ci_jfi, avg_util, ci_util, algorithm_names);

fprintf('\nSimulation completed successfully!\n');
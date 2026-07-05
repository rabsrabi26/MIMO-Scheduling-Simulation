%% Impact of Service Type Distribution on Avg. Waiting Time
% This script runs simulations with different service type distributions

clear all; close all; clc;

% Simulation parameters
service_distributions = [0.2, 0.4, 0.6, 0.8];  % Percentage of Type 0 (Voice/Video) traffic
numUsers = 20;                                  % Fixed number of users
numAntennas = 16;                               % Fixed number of antennas
cellRadius = 500;                               % Cell radius in meters
simulationRuns = 20;                            % Number of simulation runs per configuration

% Priority scheduler parameters
alpha = 0.7;           % Weight for distance component
beta = 0.3;            % Weight for service type component

% Multilevel queue parameters
queue_ranges = [0, 125; 125, 250; 250, 375; 375, 500]; % Distance ranges for queues

algorithm_names = {'Priority', 'Multilevel Queue', 'Round Robin', 'Proportional Fair', 'Max C/I'};

% Initialize results storage
await_results = zeros(length(service_distributions), 5);

fprintf('Running simulations for varying service type distributions...\n');
progress = waitbar(0, 'Starting simulations...');

for s_idx = 1:length(service_distributions)
    type0_percentage = service_distributions(s_idx);
    waitbar(s_idx/length(service_distributions), progress, sprintf('Testing %.0f%% Type 0 traffic', type0_percentage*100));
    
    % Initialize temporary storage for this configuration
    await_temp = zeros(simulationRuns, 5);
    
    for run = 1:simulationRuns
        % Generate User Parameters with custom service type distribution
        [userLocations, userDistances] = generateUsers(numUsers, cellRadius);
        [serviceTypes, arrivalTimes, burstTimes] = generateTrafficCustom(numUsers, type0_percentage);
        
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
        [awt_priority, ~, ~, ~] = scheduler_priority(users, numAntennas, alpha, beta);
        [awt_multilevel, ~, ~, ~] = scheduler_multilevel(users, numAntennas, queue_ranges, alpha, beta);
        [awt_rr, ~, ~, ~] = scheduler_rr(users, numAntennas);
        [awt_pf, ~, ~, ~] = scheduler_pf(users, numAntennas);
        [awt_maxci, ~, ~, ~] = scheduler_maxci(users, numAntennas);
        
        % Store results for this run
        await_temp(run, :) = [awt_priority, awt_multilevel, awt_rr, awt_pf, awt_maxci];
    end
    
    % Calculate averages for this configuration
    await_results(s_idx, :) = mean(await_temp, 1);
end

close(progress);

% Plot results
figure('Position', [100, 100, 800, 600]);
hold on;
colors = ['r', 'g', 'b', 'c', 'm'];
for algo = 1:5
    plot(service_distributions*100, await_results(:, algo), ['-o' colors(algo)], 'LineWidth', 2, 'DisplayName', algorithm_names{algo});
end
title('Impact of Service Type Distribution on Average Waiting Time');
xlabel('Percentage of Type 0 (Voice/Video) Traffic (%)');
ylabel('Average Waiting Time (ms)');
legend('show');
grid on;

% Save results and figure
save('vary_service_type_results.mat', 'service_distributions', 'await_results');
saveas(gcf, 'vary_service_type_results.png');

fprintf('Simulation completed! Results saved to vary_service_type_results.mat and vary_service_type_results.png\n');

%% Helper function for custom traffic generation
function [serviceTypes, arrivalTimes, burstTimes] = generateTrafficCustom(K, type0_percentage)
    % GENERATETRAFFICCUSTOM Generate random traffic with custom service type distribution
    
    % Determine number of each service type
    num_type0 = round(K * type0_percentage);
    num_type1 = round(K * (1 - type0_percentage) * 0.6);  % 60% of remaining as Type 1
    num_type2 = K - num_type0 - num_type1;                % Rest as Type 2
    
    % Create service type array
    serviceTypes = [zeros(num_type0, 1); ones(num_type1, 1); 2*ones(num_type2, 1)];
    serviceTypes = serviceTypes(randperm(K));  % Shuffle
    
    % Arrival times: uniformly distributed between 0 and 10 ms
    arrivalTimes = 10 * rand(K, 1);
    
    % Burst times based on service type
    burstTimes = zeros(K, 1);
    for i = 1:K
        switch serviceTypes(i)
            case 0 % Voice/Video: short, urgent
                burstTimes(i) = 1 + 4 * rand(); % 1-5 ms
            case 1 % Text: moderate
                burstTimes(i) = 2 + 6 * rand(); % 2-8 ms
            case 2 % Data: longer, tolerant
                burstTimes(i) = 5 + 10 * rand(); % 5-15 ms
        end
    end
end
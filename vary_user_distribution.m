%% Impact of User Distribution on Proposed Algorithms
% This script runs simulations with different user spatial distributions

clear all; close all; clc;

% Simulation parameters
numUsers = 20;         % Fixed number of users
numAntennas = 16;      % Fixed number of antennas
cellRadius = 500;      % Cell radius in meters
simulationRuns = 20;   % Number of simulation runs per configuration

% Priority scheduler parameters
alpha = 0.7;           % Weight for distance component
beta = 0.3;            % Weight for service type component

% Multilevel queue parameters
queue_ranges = [0, 125; 125, 250; 250, 375; 375, 500]; % Distance ranges for queues

distribution_names = {'Uniform', 'Cell-Edge Clustered', 'Cell-Center Clustered'};
algorithm_names = {'Priority', 'Multilevel Queue'};

% Initialize results storage
await_results = zeros(length(distribution_names), 2);
util_results = zeros(length(distribution_names), 2);

fprintf('Running simulations for different user distributions...\n');
progress = waitbar(0, 'Starting simulations...');

for d_idx = 1:length(distribution_names)
    distribution_type = distribution_names{d_idx};
    waitbar(d_idx/length(distribution_names), progress, sprintf('Testing %s distribution', distribution_type));
    
    % Initialize temporary storage for this configuration
    await_temp = zeros(simulationRuns, 2);
    util_temp = zeros(simulationRuns, 2);
    
    for run = 1:simulationRuns
        % Generate User Parameters with specific distribution
        [userLocations, userDistances] = generateUsersCustom(numUsers, cellRadius, distribution_type);
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
        
        % Run Proposed Algorithms Only
        [awt_priority, ~, ~, util_priority] = scheduler_priority(users, numAntennas, alpha, beta);
        [awt_multilevel, ~, ~, util_multilevel] = scheduler_multilevel(users, numAntennas, queue_ranges, alpha, beta);
        
        % Store results for this run
        await_temp(run, :) = [awt_priority, awt_multilevel];
        util_temp(run, :) = [util_priority, util_multilevel];
    end
    
    % Calculate averages for this configuration
    await_results(d_idx, :) = mean(await_temp, 1);
    util_results(d_idx, :) = mean(util_temp, 1);
end

close(progress);

% Plot results
figure('Position', [100, 100, 1000, 400]);

% Plot Average Waiting Time
subplot(1, 2, 1);
bar(await_results);
set(gca, 'XTickLabel', distribution_names);
ylabel('Average Waiting Time (ms)');
title('Average Waiting Time by User Distribution');
legend(algorithm_names, 'Location', 'best');
grid on;

% Plot Resource Utilization
subplot(1, 2, 2);
bar(util_results);
set(gca, 'XTickLabel', distribution_names);
ylabel('Resource Utilization');
title('Resource Utilization by User Distribution');
legend(algorithm_names, 'Location', 'best');
grid on;

sgtitle('Impact of User Distribution on Proposed Algorithms', 'FontSize', 16, 'FontWeight', 'bold');

% Save results and figure
save('vary_user_distribution_results.mat', 'distribution_names', 'await_results', 'util_results');
saveas(gcf, 'vary_user_distribution_results.png');

fprintf('Simulation completed! Results saved to vary_user_distribution_results.mat and vary_user_distribution_results.png\n');

%% Helper function for custom user distribution generation
function [locations, distances] = generateUsersCustom(K, cellRadius, distribution_type)
    % GENERATEUSERSCUSTOM Generate users with specific spatial distribution
    
    % Preallocate arrays
    locations = zeros(K, 2);
    distances = zeros(K, 1);
    
    switch distribution_type
        case 'Uniform'
            % Uniform distribution (default)
            for i = 1:K
                theta = 2 * pi * rand();
                r = cellRadius * sqrt(rand());
                x = r * cos(theta);
                y = r * sin(theta);
                locations(i, :) = [x, y];
                distances(i) = sqrt(x^2 + y^2);
            end
            
        case 'Cell-Edge Clustered'
            % 60% of users at cell edge, 40% uniformly distributed
            num_edge = round(K * 0.6);
            num_uniform = K - num_edge;
            
            % Edge users (outer 20% of cell radius)
            for i = 1:num_edge
                theta = 2 * pi * rand();
                r = cellRadius * (0.8 + 0.2 * rand()); % 80-100% of cell radius
                x = r * cos(theta);
                y = r * sin(theta);
                locations(i, :) = [x, y];
                distances(i) = sqrt(x^2 + y^2);
            end
            
            % Uniformly distributed users
            for i = num_edge+1:K
                theta = 2 * pi * rand();
                r = cellRadius * sqrt(rand());
                x = r * cos(theta);
                y = r * sin(theta);
                locations(i, :) = [x, y];
                distances(i) = sqrt(x^2 + y^2);
            end
            
        case 'Cell-Center Clustered'
            % 60% of users at cell center, 40% uniformly distributed
            num_center = round(K * 0.6);
            num_uniform = K - num_center;
            
            % Center users (inner 20% of cell radius)
            for i = 1:num_center
                theta = 2 * pi * rand();
                r = cellRadius * 0.2 * sqrt(rand()); % 0-20% of cell radius
                x = r * cos(theta);
                y = r * sin(theta);
                locations(i, :) = [x, y];
                distances(i) = sqrt(x^2 + y^2);
            end
            
            % Uniformly distributed users
            for i = num_center+1:K
                theta = 2 * pi * rand();
                r = cellRadius * sqrt(rand());
                x = r * cos(theta);
                y = r * sin(theta);
                locations(i, :) = [x, y];
                distances(i) = sqrt(x^2 + y^2);
            end
    end
end
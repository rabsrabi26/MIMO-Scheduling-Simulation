function [avg_waiting_time, avg_turnaround_time, jfi, utilization] = scheduler_pf(users, M)
    % PROPORTIONAL_FAIR_SCHEDULER Implementation of Proportional Fair Scheduling
    
    numUsers = length(users);
    
    % Initialize variables
    antenna_free_time = zeros(1, M);
    completion_time = zeros(1, numUsers);
    remaining_time = [users.burst_time];
    avg_throughput = zeros(1, numUsers) + 0.1; % Small initial value to avoid division by zero
    tc = 10; % Time constant for exponential averaging
    
    % PF scheduling
    while any(remaining_time > 0)
        % Find next available antenna
        [earliest_time, ant_idx] = min(antenna_free_time);
        
        % Find user with highest PF metric
        best_metric = -inf;
        best_user = 0;
        
        for u = 1:numUsers
            if remaining_time(u) > 0 && users(u).arrival_time <= earliest_time
                % Instantaneous rate is inversely proportional to burst time
                instant_rate = 1 / users(u).burst_time * users(u).path_loss;
                
                % PF metric
                metric = instant_rate / avg_throughput(u);
                
                if metric > best_metric
                    best_metric = metric;
                    best_user = u;
                end
            end
        end
        
        if best_user == 0
            % No user is ready, advance time
            antenna_free_time(ant_idx) = antenna_free_time(ant_idx) + 0.1;
            continue;
        end
        
        % Serve the best user
        start_time = max(earliest_time, users(best_user).arrival_time);
        end_time = start_time + users(best_user).burst_time;
        
        % Update completion and remaining time
        completion_time(best_user) = end_time;
        remaining_time(best_user) = 0;
        
        % Update average throughput
        user_throughput = users(best_user).burst_time / (end_time - users(best_user).arrival_time);
        avg_throughput(best_user) = (1 - 1/tc) * avg_throughput(best_user) + (1/tc) * user_throughput;
        
        % Update antenna free time
        antenna_free_time(ant_idx) = end_time;
    end
    
    % Calculate performance metrics
    turnaround_time = completion_time - [users.arrival_time];
    waiting_time = turnaround_time - [users.burst_time];
    
    avg_waiting_time = mean(waiting_time);
    avg_turnaround_time = mean(turnaround_time);
    
    % Calculate Jain's Fairness Index
    user_throughput = [users.burst_time] ./ turnaround_time;
    jfi = (sum(user_throughput))^2 / (numUsers * sum(user_throughput.^2));
    
    % Calculate resource utilization
    total_time = max(completion_time);
    utilization = sum([users.burst_time]) / (M * total_time);
end
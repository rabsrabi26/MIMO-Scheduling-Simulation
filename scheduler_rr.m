function [avg_waiting_time, avg_turnaround_time, jfi, utilization] = scheduler_rr(users, M)
    % ROUND_ROBIN_SCHEDULER Implementation of Round Robin Scheduling
    
    numUsers = length(users);
    
    % Sort users by arrival time
    [~, sortIdx] = sort([users.arrival_time]);
    sortedUsers = users(sortIdx);
    
    % Initialize variables
    antenna_free_time = zeros(1, M);
    completion_time = zeros(1, numUsers);
    remaining_time = [sortedUsers.burst_time];
    user_ptr = 1;
    time_quantum = 2; % ms
    
    % Round Robin scheduling
    while any(remaining_time > 0)
        % Find next available antenna
        [earliest_time, ant_idx] = min(antenna_free_time);
        
        % Find next user to serve
        user_found = false;
        for i = 0:numUsers-1
            test_user = mod(user_ptr + i - 1, numUsers) + 1;
            
            if remaining_time(test_user) > 0 && sortedUsers(test_user).arrival_time <= earliest_time
                user_ptr = test_user;
                user_found = true;
                break;
            end
        end
        
        if ~user_found
            % No user is ready, advance time
            antenna_free_time(ant_idx) = antenna_free_time(ant_idx) + 0.1;
            continue;
        end
        
        % Serve the user for a time quantum or until completion
        service_time = min(time_quantum, remaining_time(user_ptr));
        start_time = max(earliest_time, sortedUsers(user_ptr).arrival_time);
        end_time = start_time + service_time;
        
        % Update remaining time and completion time
        remaining_time(user_ptr) = remaining_time(user_ptr) - service_time;
        if remaining_time(user_ptr) <= 0
            completion_time(user_ptr) = end_time;
        end
        
        % Update antenna free time
        antenna_free_time(ant_idx) = end_time;
        
        % Move to next user
        user_ptr = mod(user_ptr, numUsers) + 1;
    end
    
    % Calculate performance metrics
    turnaround_time = completion_time - [sortedUsers.arrival_time];
    waiting_time = turnaround_time - [sortedUsers.burst_time];
    
    avg_waiting_time = mean(waiting_time);
    avg_turnaround_time = mean(turnaround_time);
    
    % Calculate Jain's Fairness Index
    user_throughput = [sortedUsers.burst_time] ./ turnaround_time;
    jfi = (sum(user_throughput))^2 / (numUsers * sum(user_throughput.^2));
    
    % Calculate resource utilization
    total_time = max(completion_time);
    utilization = sum([sortedUsers.burst_time]) / (M * total_time);
end
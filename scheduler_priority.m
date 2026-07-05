function [avg_waiting_time, avg_turnaround_time, jfi, utilization] = scheduler_priority(users, M, alpha, beta)
    % PRIORITY_SCHEDULER Implementation of Location-and-Service Priority Scheduling
    
    numUsers = length(users);
    maxDistance = max([users.distance]);
    
    % Calculate Priority Score for each user
    for u = 1:numUsers
        normalized_distance = 1 - (users(u).distance / maxDistance);
        
        % Map service type to weight
        switch users(u).service_type
            case 0 % Voice/Video
                service_weight = 1.0;
            case 1 % Text
                service_weight = 0.5;
            case 2 % Data
                service_weight = 0.2;
        end
        
        users(u).priority_score = alpha * normalized_distance + beta * service_weight;
    end
    
    % Sort users by priority (descending)
    [~, sortIdx] = sort([users.priority_score], 'descend');
    sortedUsers = users(sortIdx);
    
    % Simulate Scheduling onto M antennas
    antenna_free_time = zeros(1, M);
    completion_time = zeros(1, numUsers);
    served_users = 0;
    
    for u = 1:numUsers
        currentUser = sortedUsers(u);
        [earliest_time, ant_idx] = min(antenna_free_time);
        
        start_time = max(earliest_time, currentUser.arrival_time);
        comp_time = start_time + currentUser.burst_time;
        
        completion_time(sortIdx(u)) = comp_time;
        antenna_free_time(ant_idx) = comp_time;
        served_users = served_users + 1;
    end
    
    % Calculate performance metrics
    turnaround_time = completion_time - [users.arrival_time];
    waiting_time = turnaround_time - [users.burst_time];
    
    avg_waiting_time = mean(waiting_time);
    avg_turnaround_time = mean(turnaround_time);
    
    % Calculate Jain's Fairness Index for throughput
    user_throughput = [users.burst_time] ./ turnaround_time;
    jfi = (sum(user_throughput))^2 / (numUsers * sum(user_throughput.^2));
    
    % Calculate resource utilization
    total_time = max(completion_time);
    utilization = sum([users.burst_time]) / (M * total_time);
end
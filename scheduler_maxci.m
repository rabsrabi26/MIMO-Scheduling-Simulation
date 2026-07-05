function [avg_waiting_time, avg_turnaround_time, jfi, utilization] = scheduler_maxci(users, M)
    % MAX_CI_SCHEDULER Implementation of Max C/I Scheduling
    
    numUsers = length(users);
    
    % Sort users by channel quality (path loss)
    [~, sortIdx] = sort([users.path_loss], 'descend');
    sortedUsers = users(sortIdx);
    
    % Simulate Scheduling onto M antennas
    antenna_free_time = zeros(1, M);
    completion_time = zeros(1, numUsers);
    
    for u = 1:numUsers
        currentUser = sortedUsers(u);
        [earliest_time, ant_idx] = min(antenna_free_time);
        
        start_time = max(earliest_time, currentUser.arrival_time);
        comp_time = start_time + currentUser.burst_time;
        
        completion_time(sortIdx(u)) = comp_time;
        antenna_free_time(ant_idx) = comp_time;
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
function [avg_waiting_time, avg_turnaround_time, jfi, utilization] = scheduler_multilevel(users, M, queue_ranges, alpha, beta)
    % MULTILEVEL_QUEUE_SCHEDULER Implementation of Multilevel Queue Scheduling
    
    numQueues = size(queue_ranges, 1);
    queues = cell(1, numQueues);
    
    % Assign users to queues based on distance
    for u = 1:length(users)
        assigned = false;
        for q = 1:numQueues
            if users(u).distance >= queue_ranges(q,1) && users(u).distance < queue_ranges(q,2)
                queues{q} = [queues{q}, users(u)];
                assigned = true;
                break;
            end
        end
        if ~assigned
            queues{end} = [queues{end}, users(u)];
        end
    end
    
    % Process queues in order of priority (Q1 highest -> QN lowest)
    current_time = 0;
    abs_completion_time = inf(1, length(users));
    
    for q = 1:numQueues
        if ~isempty(queues{q})
            % Process the current queue using the Priority Scheduler
            [~, ~, jfi_q, util_q, comp_times_relative] = process_queue(queues{q}, M, alpha, beta, current_time);
            
            % Convert relative completion times to absolute system times
            for idx = 1:length(queues{q})
                original_user_id = queues{q}(idx).id;
                abs_completion_time(original_user_id) = current_time + comp_times_relative(idx);
            end
            
            % Update the global system time tracker
            current_time = current_time + max(comp_times_relative);
        end
    end
    
    % Calculate final metrics based on absolute times
    arrival_times = [users.arrival_time];
    burst_times = [users.burst_time];
    
    turnaround_time = abs_completion_time - arrival_times;
    waiting_time = turnaround_time - burst_times;
    
    avg_waiting_time = mean(waiting_time);
    avg_turnaround_time = mean(turnaround_time);
    
    % Calculate Jain's Fairness Index
    user_throughput = burst_times ./ turnaround_time;
    jfi = (sum(user_throughput))^2 / (length(users) * sum(user_throughput.^2));
    
    % Calculate resource utilization
    total_time = max(abs_completion_time);
    utilization = sum(burst_times) / (M * total_time);
end

function [avg_waiting_time, avg_turnaround_time, jfi, utilization, completion_time] = process_queue(users, M, alpha, beta, start_time)
    % PROCESS_QUEUE Helper function to process a single queue
    
    numUsers = length(users);
    maxDistance = max([users.distance]);
    
    % Calculate Priority Score for each user in the queue
    for u = 1:numUsers
        normalized_distance = 1 - (users(u).distance / maxDistance);
        
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
    antenna_free_time = zeros(1, M) + start_time;
    completion_time = zeros(1, numUsers);
    
    for u = 1:numUsers
        currentUser = sortedUsers(u);
        [earliest_time, ant_idx] = min(antenna_free_time);
        
        start_time_user = max(earliest_time, currentUser.arrival_time);
        comp_time = start_time_user + currentUser.burst_time;
        
        completion_time(sortIdx(u)) = comp_time;
        antenna_free_time(ant_idx) = comp_time;
    end
    
    % Calculate performance metrics for this queue
    turnaround_time = completion_time - [users.arrival_time];
    waiting_time = turnaround_time - [users.burst_time];
    
    avg_waiting_time = mean(waiting_time);
    avg_turnaround_time = mean(turnaround_time);
    
    % Calculate Jain's Fairness Index for this queue
    user_throughput = [users.burst_time] ./ turnaround_time;
    jfi = (sum(user_throughput))^2 / (numUsers * sum(user_throughput.^2));
    
    % Calculate resource utilization for this queue
    total_time = max(completion_time) - start_time;
    utilization = sum([users.burst_time]) / (M * total_time);
end
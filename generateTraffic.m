function [serviceTypes, arrivalTimes, burstTimes] = generateTraffic(K)
    % GENERATETRAFFIC Generate random traffic parameters for users.
    
    % Service type distribution: 30% Voice/Video, 40% Text, 30% Data
    serviceTypes = randsrc(K, 1, [0, 1, 2; 0.3, 0.4, 0.3]);
    
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
function pathLoss = calculatePathLoss(distances, cellRadius)
    % CALCULATEPATHLOSS Calculate path loss for given distances.
    
    % Path loss parameters
    PL_0 = 30;          % Path loss at reference distance (1m) in dB
    gamma = 3.5;        % Path loss exponent
    sigma_sh = 8;       % Shadow fading standard deviation in dB
    
    % Convert distance from meters to kilometers for practical path loss models
    d_km = max(distances, 1) / 1000; % Avoid log(0), minimum distance 1m
    
    % Calculate path loss in dB (simplified model)
    PL_dB = PL_0 + 10 * gamma * log10(d_km) + sigma_sh * randn(size(distances));
    
    % Convert to linear scale
    pathLoss = 10.^(-PL_dB / 10);
end
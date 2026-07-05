function [locations, distances] = generateUsers(K, cellRadius)
    % GENERATEUSERS Generate random user locations within a circular cell.
    %   [LOCATIONS, DISTANCES] = GENERATEUSERS(K, CELLRADIUS) generates K
    %   user locations uniformly distributed within a circle of given CELLRADIUS.
    
    % Preallocate arrays
    locations = zeros(K, 2);
    distances = zeros(K, 1);
    
    for i = 1:K
        % Generate uniform random angle
        theta = 2 * pi * rand();
        
        % Generate uniform random radius (sqrt for uniform distribution in area)
        r = cellRadius * sqrt(rand());
        
        % Convert polar to Cartesian coordinates
        x = r * cos(theta);
        y = r * sin(theta);
        
        locations(i, :) = [x, y];
        distances(i) = sqrt(x^2 + y^2); % Euclidean distance from origin (0,0)
    end
end
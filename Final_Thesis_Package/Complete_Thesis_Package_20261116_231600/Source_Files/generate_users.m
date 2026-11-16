function users = generate_users(cfg, stream)
%GENERATE_USERS Generate users uniformly by area in a circular cell.
K = cfg.numUsers;
theta = 2*pi*rand(stream,K,1);
radius = cfg.cellRadius_m*sqrt(rand(stream,K,1));
users.id = (1:K)';
users.x_m = radius.*cos(theta);
users.y_m = radius.*sin(theta);
users.distance_m = radius;
users.arrival_ms = cfg.arrivalWindow_ms*rand(stream,K,1);
p = cfg.serviceProbabilities(:)'/sum(cfg.serviceProbabilities);
u = rand(stream,K,1);
cdfp = cumsum(p);
users.service_type = zeros(K,1);
for k=1:K
    users.service_type(k) = find(u(k)<=cdfp,1,'first')-1;
end
users.work_ms = zeros(K,1);
for k=1:K
    r = cfg.serviceDemandRanges_ms(users.service_type(k)+1,:);
    users.work_ms(k) = r(1)+(r(2)-r(1))*rand(stream);
end
end

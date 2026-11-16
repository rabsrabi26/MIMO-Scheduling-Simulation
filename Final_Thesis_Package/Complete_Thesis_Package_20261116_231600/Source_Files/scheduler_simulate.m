
function out = scheduler_simulate(users, ch, cfg, algorithm)
%SCHEDULER_SIMULATE Event-driven, non-duplicating multi-server scheduler.
% Each antenna is one orthogonal service resource. A user can occupy at
% most one antenna at a time. RR and PF are preemptive by configured quanta;
% Priority, Multilevel Queue and Max C/I use non-preemptive service.
%
% Round Robin uses an arrival-ordered ready queue. New arrivals receive
% tickets in arrival order, and users whose quantum expires return to
% the back of the queue.

K = numel(users.id);
M = cfg.numAntennas;

remaining = users.work_ms(:);
arrival = users.arrival_ms(:);
rate = ch.rateFactor(:);

if any(~isfinite(rate) | rate <= 0)
    error("Channel rate factors must be finite and strictly positive.");
end
if any(~isfinite(arrival)) || any(~isfinite(remaining) | remaining <= 0)
    error("Arrival times and workloads must be finite; workloads must be positive.");
end
if M < 1 || M ~= floor(M)
    error("cfg.numAntennas must be a positive integer.");
end

completion = nan(K,1);
firstStart = nan(K,1);
busyUser = zeros(M,1);
serverFree = inf(M,1);
serverSlice = zeros(M,1);

% Round Robin queue state:
% Tickets are assigned when users arrive, not according to user ID.
rrTicket = inf(K,1);
nextTicket = 1;

avgRate = ones(K,1) * max(mean(rate), eps);
rateState = zeros(K,1);
t = min(arrival);
epsTime = 1e-10;
guard = 0;
maxEvents = max(100000, 1000*(K + M));
% MLQ diagnostic trace (does not affect scheduling decisions).
traceTime = [];
traceServer = [];
traceUser = [];
traceQueue = [];
tracePoolSize = [];
tracePriorityScore = [];
traceCandidateUsers = {};

while any(isnan(completion))
    guard = guard + 1;
    if guard > maxEvents
        error("Scheduler exceeded its event limit. Check event progression and input parameters.");
    end

    % Assign Round Robin tickets to newly arrived users in arrival order.
    % User ID breaks ties when arrival times are identical.
    if algorithm == "Round Robin"
        newReady = find(isnan(completion) & ...
            arrival <= t + epsTime & isinf(rrTicket));

        if ~isempty(newReady)
            [~, order] = sortrows([arrival(newReady), newReady], [1 2]);
            newReady = newReady(order);

            for j = 1:numel(newReady)
                rrTicket(newReady(j)) = nextTicket;
                nextTicket = nextTicket + 1;
            end
        end
    end

    % Dispatch all currently idle servers to eligible users.
    % Recalculate eligibility after each assignment so a user cannot
    % occupy two servers simultaneously.
    freeServers = find(busyUser == 0);

    for fi = 1:numel(freeServers)
        m = freeServers(fi);

        eligible = find(isnan(completion) & remaining > epsTime & ...
            arrival <= t + epsTime & ...
            ~ismember((1:K)', busyUser(busyUser > 0)));

        if isempty(eligible)
            break;
        end

        u = select_user(eligible, users, ch, cfg, algorithm, avgRate, rrTicket);
        % Record MLQ scheduling decisions for sensitivity analysis.
if algorithm == "Multilevel Queue"

    % Determine the selected user's distance queue.
    selectedQueue = get_distance_queue( ...
        users.distance_m(u), cfg.queueEdges_m);

    % Determine how many eligible users were in that queue.
    candidateQueues = get_distance_queue( ...
        users.distance_m(eligible), cfg.queueEdges_m);

    selectedPool = eligible(candidateQueues == selectedQueue);
    traceCandidateUsers{end+1,1} = selectedPool(:)';

    % Calculate the selected user's Priority score.
    d = max(users.distance_m);
    nd = 1 - users.distance_m(u)/max(d, eps);

    sw = [1.0 0.5 0.2];
    serviceWeight = sw(users.service_type(u)+1);

    selectedScore = cfg.alpha*nd + cfg.beta*serviceWeight;

    % Save the decision.
    traceTime(end+1,1) = t;
    traceServer(end+1,1) = m;
    traceUser(end+1,1) = u;
    traceQueue(end+1,1) = selectedQueue;
    tracePoolSize(end+1,1) = numel(selectedPool);
    tracePriorityScore(end+1,1) = selectedScore;

end

        if isnan(firstStart(u))
            firstStart(u) = t;
        end

        if algorithm == "Round Robin"
            slice = min(cfg.rrQuantum_ms, remaining(u)/rate(u));
        elseif algorithm == "Proportional Fair"
            slice = min(cfg.pfQuantum_ms, remaining(u)/rate(u));
        else
            slice = remaining(u)/rate(u);
        end

        if ~isfinite(slice) || slice <= 0
            error("Scheduler produced a non-positive or non-finite service slice for user %d.", u);
        end

        busyUser(m) = u;
        serverSlice(m) = slice;
        serverFree(m) = t + slice;
        rateState(u) = rate(u);
    end

    if all(~isnan(completion))
        break;
    end

    % Select the next real event: a busy server event or a future arrival.
    active = find(busyUser > 0);
    activeTimes = serverFree(active);

    futureArrivals = arrival(isnan(completion) & remaining > epsTime & ...
                             arrival > t + epsTime);

    if isempty(activeTimes) && isempty(futureArrivals)
        unfinished = find(isnan(completion));
        error("Scheduler is deadlocked: unfinished users remain but no future arrival or active service event exists (first user %d).", unfinished(1));
    elseif isempty(activeTimes)
        nextEvent = min(futureArrivals);
    elseif isempty(futureArrivals)
        nextEvent = min(activeTimes);
    else
        nextEvent = min([activeTimes; futureArrivals]);
    end

    if ~isfinite(nextEvent) || nextEvent < t - epsTime
        error("Scheduler event time is invalid (current time %.12g, next event %.12g).", t, nextEvent);
    end

    % Update exponentially averaged served rates and advance simulation time.
    dt = max(nextEvent - t, 0);

    if dt > 0
        a = 1 - exp(-dt / max(cfg.pfAveragingTime_ms, eps));
        avgRate = (1-a).*avgRate + a.*rateState;
    end

    t = nextEvent;

    % Process every server event occurring at this timestamp.
    finishedServers = find(busyUser > 0 & serverFree <= t + epsTime);

    for si = 1:numel(finishedServers)
        m = finishedServers(si);
        u = busyUser(m);

        remaining(u) = max(0, remaining(u) - serverSlice(m)*rate(u));
        rateState(u) = 0;

        if remaining(u) <= epsTime
            remaining(u) = 0;
            completion(u) = serverFree(m);

        elseif algorithm == "Round Robin"
            % Requeue the user at the back after quantum expiry.
            rrTicket(u) = nextTicket;
            nextTicket = nextTicket + 1;
        end

        busyUser(m) = 0;
        serverFree(m) = inf;
        serverSlice(m) = 0;
    end
end

if any(isnan(completion))
    error("Some users were not completed. Check arrivals and scheduler state.");
end

turnaround = completion - arrival;
waiting = turnaround - users.work_ms(:)./rate;
waiting = max(waiting, 0);

% Existing metric: Jain fairness of per-user effective completion rates.
effectiveThroughput = users.work_ms(:)./max(turnaround, eps);

if sum(effectiveThroughput.^2) == 0
    jfi = 1;
else
    jfi = sum(effectiveThroughput)^2 / ...
        (K*sum(effectiveThroughput.^2));
end

% New metric: normalized service efficiency.
serviceTime = users.work_ms(:)./rate;

serviceEfficiency = serviceTime ./ max(turnaround, eps);
serviceEfficiency = min(max(serviceEfficiency, 0), 1);

if sum(serviceEfficiency.^2) == 0
    efficiencyFairness = 1;
else
    efficiencyFairness = sum(serviceEfficiency)^2 / ...
        (K*sum(serviceEfficiency.^2));
end

makespan = max(completion) - min(arrival);
busyWork = sum(users.work_ms(:)./rate);
utilization = busyWork / (M*max(makespan, eps));

out.completion_ms = completion;
out.waiting_ms = waiting;
out.turnaround_ms = turnaround;
out.meanWaiting_ms = mean(waiting);
out.meanTurnaround_ms = mean(turnaround);
% Preserve the original metric for compatibility.
out.jainFairness = jfi;
out.jainCompletionRateFairness = jfi;

% New normalized service-efficiency metrics.
out.serviceEfficiency = serviceEfficiency;
out.meanServiceEfficiency = mean(serviceEfficiency);
out.jainServiceEfficiencyFairness = efficiencyFairness;

out.resourceUtilization = min(max(utilization, 0), 1);
% Export MLQ diagnostic trace.
if algorithm == "Multilevel Queue"

    out.scheduleTrace = table( ...
    traceTime, ...
    traceServer, ...
    traceUser, ...
    traceQueue, ...
    tracePoolSize, ...
    tracePriorityScore, ...
    traceCandidateUsers, ...
    'VariableNames', { ...
        'Time_ms', ...
        'Server', ...
        'User', ...
        'DistanceQueue', ...
        'EligibleUsersInQueue', ...
        'PriorityScore', ...
        'CandidateUsers'});

else
    out.scheduleTrace = table();
end

end


function u = select_user(candidates, users, ch, cfg, algorithm, avgRate, rrTicket)

switch algorithm

    case "Priority"
        d = max(users.distance_m);
        nd = 1 - users.distance_m(candidates)/max(d, eps);

        sw = [1.0 0.5 0.2];
        serviceWeight = sw(users.service_type(candidates)+1)';

        score = cfg.alpha*nd + cfg.beta*serviceWeight;
        [~, ix] = max(score);
        u = candidates(ix);

    case "Multilevel Queue"
        q = inf(size(candidates));

        for j = 1:size(cfg.queueEdges_m,1)
            lo = cfg.queueEdges_m(j,1);
            hi = cfg.queueEdges_m(j,2);

            if j < size(cfg.queueEdges_m,1)
                mask = users.distance_m(candidates) >= lo & ...
                       users.distance_m(candidates) < hi;
            else
                mask = users.distance_m(candidates) >= lo & ...
                       users.distance_m(candidates) <= hi;
            end

            q(mask) = j;
        end

        q(isinf(q)) = size(cfg.queueEdges_m,1);
        best = min(q);
        pool = candidates(q == best);

        u = select_user(pool, users, ch, cfg, ...
            "Priority", avgRate, rrTicket);

    case "Round Robin"
        [~, ix] = min(rrTicket(candidates));
        u = candidates(ix);

    case "Proportional Fair"
        metric = ch.rateFactor(candidates)./max(avgRate(candidates), eps);
        [~, ix] = max(metric);
        u = candidates(ix);

    case "Max C/I"
        [~, ix] = max(ch.snrLinear(candidates));
        u = candidates(ix);

    otherwise
        error("Unknown scheduler: %s", algorithm);

end

end
function q = get_distance_queue(distance, queueEdges)

q = inf(size(distance));

for j = 1:size(queueEdges,1)

    lo = queueEdges(j,1);
    hi = queueEdges(j,2);

    if j < size(queueEdges,1)
        mask = distance >= lo & distance < hi;
    else
        mask = distance >= lo & distance <= hi;
    end

    q(mask) = j;

end

q(isinf(q)) = size(queueEdges,1);

end

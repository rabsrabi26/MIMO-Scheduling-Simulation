function out = scheduler_simulate(users, ch, cfg, algorithm)
%SCHEDULER_SIMULATE Event-driven, non-duplicating multi-server scheduler.
% Each antenna is represented as one orthogonal service resource. A user
% can occupy at most one resource at a time. RR is preemptive by quantum;
% other policies use non-preemptive service until the user's work finishes.
K = numel(users.id); M = cfg.numAntennas;
remaining = users.work_ms(:);
completion = nan(K,1); firstStart = nan(K,1);
serverFree = zeros(M,1);
busyUser = zeros(M,1);
serverFinish = zeros(M,1);
serverSlice = zeros(M,1);
rrTicket = (1:K)';
nextTicket = K+1;
avgRate = ones(K,1)*max(mean(ch.rateFactor),eps);
lastUpdate = zeros(K,1);
rateState = zeros(K,1);
epsTime = 1e-10;
guard = 0;

while any(isnan(completion))
    guard = guard+1;
    if guard > 1000000
        error("Scheduler did not converge; check simulation parameters.");
    end

    % Advance to the next server event. Update each user's exponentially
    % averaged served rate over the elapsed interval before changing states.
    t = min(serverFree);
    dtAll = max(t-lastUpdate,0);
    aAll = 1-exp(-dtAll/max(cfg.pfAveragingTime_ms,eps));
    avgRate = (1-aAll).*avgRate + aAll.*rateState;
    lastUpdate(:) = t;
    for m=1:M
        if busyUser(m)>0 && serverFree(m)<=t+epsTime
            u=busyUser(m);
            elapsed=serverSlice(m);
            remaining(u)=max(0,remaining(u)-elapsed*ch.rateFactor(u));
            if remaining(u)<=epsTime
                completion(u)=serverFree(m);
            elseif algorithm=="Round Robin"
                rrTicket(u)=nextTicket; nextTicket=nextTicket+1;
            end
            rateState(u)=0;
            busyUser(m)=0;
            serverFinish(m)=0;
            serverSlice(m)=0;
        end
    end

    freeServers=find(busyUser==0);
    if isempty(freeServers), continue; end
    % Dispatch one free server at a time; active users are excluded.
    m=freeServers(1);
    eligible=find(isnan(completion) & remaining>epsTime & ...
                  users.arrival_ms(:)<=t+epsTime & ~ismember((1:K)',busyUser(busyUser>0)));
    if isempty(eligible)
        nextArrival=min(users.arrival_ms(isnan(completion) & remaining>epsTime & ...
                        users.arrival_ms>t+epsTime));
        if isempty(nextArrival)
            % If another server is active, wait for its next event.
            activeTimes=serverFree(busyUser>0);
            if isempty(activeTimes), break; end
            serverFree(m)=min(activeTimes);
        else
            serverFree(m)=nextArrival;
        end
        continue;
    end

    u=select_user(eligible,users,ch,cfg,algorithm,avgRate,rrTicket);
    if isnan(firstStart(u)), firstStart(u)=t; end
    if algorithm=="Round Robin"
        slice=min(cfg.rrQuantum_ms,remaining(u)/ch.rateFactor(u));
    elseif algorithm=="Proportional Fair"
        slice=min(cfg.pfQuantum_ms,remaining(u)/ch.rateFactor(u));
    else
        slice=remaining(u)/ch.rateFactor(u);
    end
    slice=max(slice,epsTime);
    rateState(u)=ch.rateFactor(u);
    busyUser(m)=u;
    serverSlice(m)=slice;
    serverFree(m)=t+slice;

end

if any(isnan(completion))
    error("Some users were not completed. Check arrivals and scheduler state.");
end
turnaround=completion-users.arrival_ms(:);
waiting=turnaround-users.work_ms(:)./ch.rateFactor(:);
waiting=max(waiting,0);
effectiveThroughput=users.work_ms(:)./max(turnaround,eps);
if sum(effectiveThroughput.^2)==0
    jfi=1;
else
    jfi=sum(effectiveThroughput)^2/(K*sum(effectiveThroughput.^2));
end
makespan=max(completion)-min(users.arrival_ms);
busyWork=sum(users.work_ms(:)./ch.rateFactor(:));
utilization=busyWork/(M*max(makespan,eps));
out.completion_ms=completion;
out.waiting_ms=waiting;
out.turnaround_ms=turnaround;
out.meanWaiting_ms=mean(waiting);
out.meanTurnaround_ms=mean(turnaround);
out.jainFairness=jfi;
out.resourceUtilization=min(max(utilization,0),1);
end

function u = select_user(candidates,users,ch,cfg,algorithm,avgRate,rrTicket)
switch algorithm
    case "Priority"
        d=max(users.distance_m);
        nd=1-users.distance_m(candidates)/max(d,eps);
        sw=[1.0 0.5 0.2];
        serviceWeight=sw(users.service_type(candidates)+1)';
        score=cfg.alpha*nd+cfg.beta*serviceWeight;
        [~,ix]=max(score); u=candidates(ix);
    case "Multilevel Queue"
        % Queue 1 is cell-centre/highest priority. Distance bands are
        % half-open except the final band, which includes the cell edge.
        q=inf(size(candidates));
        for j=1:size(cfg.queueEdges_m,1)
            lo=cfg.queueEdges_m(j,1); hi=cfg.queueEdges_m(j,2);
            if j<size(cfg.queueEdges_m,1)
                mask=users.distance_m(candidates)>=lo & users.distance_m(candidates)<hi;
            else
                mask=users.distance_m(candidates)>=lo & users.distance_m(candidates)<=hi;
            end
            q(mask)=j;
        end
        q(isinf(q))=size(cfg.queueEdges_m,1);
        best=min(q); pool=candidates(q==best);
        % Within each queue, use the same location/service priority.
        u=select_user(pool,users,ch,cfg,"Priority",avgRate,rrTicket);
    case "Round Robin"
        [~,ix]=min(rrTicket(candidates)); u=candidates(ix);
    case "Proportional Fair"
        metric=ch.rateFactor(candidates)./max(avgRate(candidates),eps);
        [~,ix]=max(metric); u=candidates(ix);
    case "Max C/I"
        [~,ix]=max(ch.snrLinear(candidates)); u=candidates(ix);
    otherwise
        error("Unknown scheduler: %s",algorithm);
end
end

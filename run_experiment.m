function results = run_experiment(cfg)
%RUN_EXPERIMENT Run paired Monte Carlo trials for all scheduling policies.

rng(cfg.seed,"twister");

A = cfg.algorithms;
R = cfg.numRuns;
K = cfg.numUsers;

metrics = ["waiting", "turnaround", "fairness", ...
           "efficiencyFairness", "meanServiceEfficiency", ...
           "utilization"];

raw = struct();

for q = metrics
    raw.(q) = zeros(R, numel(A));
end

for r = 1:R

    stream = RandStream("mt19937ar", "Seed", cfg.seed+1000*r);

    users = generate_users(cfg, stream);
    ch = calculate_channel(users, cfg, stream);

    for a = 1:numel(A)

        s = scheduler_simulate(users, ch, cfg, A(a));

        raw.waiting(r,a) = s.meanWaiting_ms;
        raw.turnaround(r,a) = s.meanTurnaround_ms;

        % Original completion-rate fairness.
        raw.fairness(r,a) = s.jainFairness;

        % New normalized service-efficiency metrics.
        raw.efficiencyFairness(r,a) = ...
            s.jainServiceEfficiencyFairness;

        raw.meanServiceEfficiency(r,a) = ...
            s.meanServiceEfficiency;

        raw.utilization(r,a) = s.resourceUtilization;

    end
end

results.raw = raw;

for q = metrics

    x = raw.(q);

    results.summary.(q).mean = mean(x,1);
    results.summary.(q).std = std(x,0,1);
    results.summary.(q).ci95 = ...
        1.96*std(x,0,1)/sqrt(R);

end

results.algorithms = A;
results.numRuns = R;
results.numUsers = K;
results.numAntennas = cfg.numAntennas;

end

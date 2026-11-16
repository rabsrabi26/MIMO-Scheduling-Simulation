
% RUN_INDEPENDENT_SEED_VALIDATION
% Independent Monte Carlo experiment using a new random seed.
% Keeps all final scheduling configurations unchanged.

clc;

fprintf("\n========================================\n");
fprintf(" INDEPENDENT SEED VALIDATION\n");
fprintf("========================================\n");

%% Experimental configuration

baseCfg = default_config();

baseCfg.numRuns = 100;
baseCfg.numAntennas = 16;
baseCfg.seed = 20261116;

baseCfg.alpha = 0.5;
baseCfg.beta = 0.5;

userLoads = [20 40 60];

%% Run independent experiments

for k = 1:numel(userLoads)

    cfg = baseCfg;
    cfg.numUsers = userLoads(k);

    fprintf("\nRunning independent experiment: %d users\n", ...
        cfg.numUsers);

    results = run_experiment(cfg);

    switch cfg.numUsers
        case 20
            results20_independent = results;
            cfg20_independent = cfg;

        case 40
            results40_independent = results;
            cfg40_independent = cfg;

        case 60
            results60_independent = results;
            cfg60_independent = cfg;
    end

    fprintf("Completed %d users.\n", cfg.numUsers);
    disp(results.summary);

end

%% Save independent results

save("independent_seed_results.mat", ...
    "results20_independent", ...
    "results40_independent", ...
    "results60_independent", ...
    "cfg20_independent", ...
    "cfg40_independent", ...
    "cfg60_independent");

fprintf("\n========================================\n");
fprintf(" INDEPENDENT EXPERIMENTS COMPLETED\n");
fprintf("========================================\n");

fprintf("Runs per scenario: 100\n");
fprintf("Independent seed: 20261116\n");
fprintf("Alpha: 0.5 | Beta: 0.5\n");
fprintf("Antennas: 16\n");
fprintf("Results saved in independent_seed_results.mat\n");

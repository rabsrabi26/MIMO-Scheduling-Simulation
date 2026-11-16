
% RUN_FINAL_EXPERIMENTS
% Final paired Monte Carlo experiments.
% Priority and MLQ use alpha = beta = 0.5.

clc;

fprintf("\n========================================\n");
fprintf(" FINAL THESIS EXPERIMENTS\n");
fprintf("========================================\n");

%% Common configuration

baseCfg = default_config();

baseCfg.numRuns = 100;
baseCfg.numAntennas = 16;
baseCfg.seed = 20261115;
baseCfg.alpha = 0.5;
baseCfg.beta = 0.5;

%% Experiment 1: 20 users

cfg20 = baseCfg;
cfg20.numUsers = 20;

fprintf("\nRunning 20-user experiment...\n");
results20_final = run_experiment(cfg20);
fprintf("20-user experiment completed.\n");

%% Experiment 2: 40 users

cfg40 = baseCfg;
cfg40.numUsers = 40;

fprintf("\nRunning 40-user experiment...\n");
results40_final = run_experiment(cfg40);
fprintf("40-user experiment completed.\n");

%% Experiment 3: 60 users

cfg60 = baseCfg;
cfg60.numUsers = 60;

fprintf("\nRunning 60-user experiment...\n");
results60_final = run_experiment(cfg60);
fprintf("60-user experiment completed.\n");

%% Save results separately

save("final_thesis_results.mat", ...
    "results20_final", "results40_final", ...
    "results60_final", "cfg20", "cfg40", "cfg60");

fprintf("\nFinal results saved successfully.\n");

%% Display summaries

fprintf("\n========== 20 USERS ==========\n");
disp(results20_final.summary);

fprintf("\n========== 40 USERS ==========\n");
disp(results40_final.summary);

fprintf("\n========== 60 USERS ==========\n");
disp(results60_final.summary);

fprintf("\nALL FINAL EXPERIMENTS COMPLETED.\n");

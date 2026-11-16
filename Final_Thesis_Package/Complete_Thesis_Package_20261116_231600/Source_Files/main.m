%% MIMO scheduling study - corrected event-driven simulation
% Run this script from the project directory in MATLAB.
clear; clc; close all;

cfg = default_config();
cfg.numRuns = 100;
cfg.numUsers = 20;
cfg.numAntennas = 16;
cfg.seed = 20261115;
cfg.outputDir = "results";

if ~isfolder(cfg.outputDir), mkdir(cfg.outputDir); end
results = run_experiment(cfg);
save(fullfile(cfg.outputDir, "main_results.mat"), "results", "cfg");
plot_results(results, cfg, fullfile(cfg.outputDir, "main_results.png"));
disp(results.summary);
fprintf("\nFinished. Results saved in %s\n", cfg.outputDir);

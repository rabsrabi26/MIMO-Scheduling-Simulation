%% Sensitivity study: users and antennas
clear; clc; close all;
base=default_config(); base.numRuns=50; base.seed=1234;
userCounts=[10 20 30 40]; antennaCounts=[4 8 16 32 64];
out=struct();
for i=1:numel(userCounts)
    cfg=base; cfg.numUsers=userCounts(i);
    for j=1:numel(antennaCounts)
        cfg.numAntennas=antennaCounts(j);
        out(i,j).K=cfg.numUsers; out(i,j).M=cfg.numAntennas;
        out(i,j).result=run_experiment(cfg);
        fprintf("Completed K=%d, M=%d\n",cfg.numUsers,cfg.numAntennas);
    end
end
if ~isfolder("results"), mkdir("results"); end
save("results/sensitivity_results.mat","out","userCounts","antennaCounts","base");

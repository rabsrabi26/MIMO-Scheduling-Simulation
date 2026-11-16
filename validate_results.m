%% Basic invariant checks for the corrected scheduler
clear; clc;
cfg=default_config(); cfg.numRuns=3; cfg.numUsers=20; cfg.numAntennas=4;
stream=RandStream("mt19937ar","Seed",77);
u=generate_users(cfg,stream); ch=calculate_channel(u,cfg,stream);
for a=cfg.algorithms
    s=scheduler_simulate(u,ch,cfg,a);
    assert(all(isfinite(s.completion_ms)) && all(s.completion_ms>=u.arrival_ms));
    assert(all(s.waiting_ms>=-1e-8));
    assert(s.jainFairness>=1/cfg.numUsers-1e-8 && s.jainFairness<=1+1e-8);
    assert(s.resourceUtilization>=0 && s.resourceUtilization<=1);
    fprintf("%s: invariants passed\n",a);
end

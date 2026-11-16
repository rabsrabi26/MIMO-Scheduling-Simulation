function cfg = default_config()
%DEFAULT_CONFIG Shared, documented parameters for all experiments.
cfg.numRuns = 50;
cfg.numUsers = 20;
cfg.numAntennas = 16;
cfg.cellRadius_m = 500;
cfg.bandwidth_Hz = 10e6;
cfg.noisePower_dBm = -104;       % Receiver noise over configured bandwidth
cfg.txPower_dBm = 30;            % Per-user downlink-equivalent reference power
cfg.pathLoss1m_dB = 30;           % Path loss at 1 metre
cfg.pathLossExponent = 3.5;
cfg.shadowStd_dB = 8;
cfg.arrivalWindow_ms = 10;
cfg.rrQuantum_ms = 2;
cfg.pfQuantum_ms = 1;           % PF scheduling interval for time-sharing
cfg.pfAveragingTime_ms = 10;
cfg.alpha = 0.7;
cfg.beta = 0.3;
cfg.queueEdges_m = [0 125; 125 250; 250 375; 375 500];
cfg.serviceProbabilities = [0.3 0.4 0.3]; % service classes 0,1,2
cfg.serviceDemandRanges_ms = [1 5; 2 8; 5 15];
cfg.randomSeed = 1;
cfg.algorithms = ["Priority","Multilevel Queue","Round Robin", ...
                  "Proportional Fair","Max C/I"];
end

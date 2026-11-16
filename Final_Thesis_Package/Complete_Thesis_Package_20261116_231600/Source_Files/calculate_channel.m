function ch = calculate_channel(users, cfg, stream)
%CALCULATE_CHANNEL Log-distance large-scale channel model.
% Path loss is positive dB and channel power gain is 10^(-PL/10).
% Small-scale fading, antenna correlation, precoding and interference are
% deliberately not modelled in this large-scale scheduling abstraction.
d = max(users.distance_m,1);
shadow = cfg.shadowStd_dB*randn(stream,numel(d),1);
ch.pathLoss_dB = cfg.pathLoss1m_dB + ...
    10*cfg.pathLossExponent*log10(d) + shadow;
ch.gainLinear = 10.^(-ch.pathLoss_dB/10);
noiseW = 10.^((cfg.noisePower_dBm-30)/10);
txW = 10.^((cfg.txPower_dBm-30)/10);
ch.snrLinear = max(txW.*ch.gainLinear./noiseW,1e-12);
ch.spectralEfficiency = log2(1+ch.snrLinear);
% Normalize around the cell's mean so service demand remains interpretable.
ch.rateFactor = ch.spectralEfficiency./max(mean(ch.spectralEfficiency),eps);
ch.rateFactor = max(ch.rateFactor,0.05);
end

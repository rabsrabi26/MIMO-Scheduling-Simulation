# MIMO Scheduling Simulation — reviewed implementation

This is a corrected, reproducible MATLAB scheduling simulator based on the
original repository's five-policy comparison:

1. Priority (distance + service class)
2. Multilevel Queue (distance bands, strict queue priority)
3. Round Robin (preemptive time quantum)
4. Proportional Fair (instantaneous channel rate / moving-average rate)
5. Max C/I (best channel among currently eligible users)

## Important modelling scope

The original project uses the number of base-station antennas as the number
of independent servers. This package preserves that abstraction so the
scheduling policies can be compared consistently. It is **not a complete
physical-layer Massive MIMO simulator**: it does not implement channel
vectors, spatial multiplexing, precoding/combining, antenna correlation,
multiuser interference, or SINR after precoding. The channel model here is
large-scale log-distance path loss plus log-normal shadowing, converted to a
rate factor using Shannon spectral efficiency.

The generated `work_ms` is a workload at the normalized reference rate.
Actual service duration is workload divided by the user's channel rate factor.
Every user is reserved on at most one server at a time. RR can be preempted
after its configured quantum; other policies are non-preemptive.

## Requirements

- MATLAB R2021a or newer recommended.
- Base MATLAB only; no Communications Toolbox functions such as `randsrc`
  are required.

## Run

```matlab
main
```

For the parameter grid:

```matlab
run_sensitivity
```

Run basic invariant checks:

```matlab
validate_results
```

Outputs are saved under `results/`.

## Metrics

- Waiting time = completion time − arrival time − actual service time.
- Turnaround time = completion time − arrival time.
- Jain fairness = Jain index of per-user delivered workload divided by
  turnaround time.
- Resource utilization = total occupied server-time / (M × measured makespan).

Confidence intervals are 95% normal-approximation intervals over independent
Monte Carlo runs. For publication-grade inference, increase the number of
runs and consider Student-t intervals or bootstrap intervals.

## Reproducibility

`cfg.seed` controls the experiment seed. The same generated user/channel
scenario is used for all algorithms within a run (paired comparison), reducing
variance in policy comparisons.

## Research caution

The scheduler definitions and system abstraction must match the thesis
methodology and cited literature. In particular, strict-priority distance
queues, service-class priority weights, and the choice of channel-aware
service model are modelling decisions, not universal definitions. Validate
these assumptions with your supervisor and thesis equations before using
the numerical results as final research claims.

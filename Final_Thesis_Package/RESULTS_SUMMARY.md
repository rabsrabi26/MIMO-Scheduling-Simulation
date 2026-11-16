# Final thesis results summary

## Experiment configuration

- Combined Monte Carlo runs: 200 per scenario (20, 40, and 60 users).
- Abstract service resources: 16.
- Scheduling policies: Priority, Multilevel Queue, Round Robin, Proportional Fair, and Max C/I.
- Final Priority weights: alpha = 0.5, beta = 0.5.

## Statistical validation

| Scenario | Comparisons | Significant paired t-tests | Significant Wilcoxon tests | Test agreement |
|---|---:|---:|---:|---:|
| 20 users | 42 | 0 | 8 | 34/42 |
| 40 users | 42 | 35 | 33 | 40/42 |
| 60 users | 42 | 37 | 35 | 38/42 |

## Priority minus Multilevel Queue

Positive differences mean Priority has a higher metric value.

| Scenario | Metric | Mean difference | Holm t-test p | Holm Wilcoxon p | Cohen's dz |
|---|---|---:|---:|---:|---:|
| 20 users | Waiting | -0.00000209 ms | 1 | 1 | -0.071 |
| 20 users | Turnaround | -0.00000209 ms | 1 | 1 | -0.071 |
| 20 users | Completion fairness | 0.00000064 | 1 | 1 | 0.071 |
| 20 users | Service-efficiency fairness | 0.00000040 | 1 | 1 | 0.071 |
| 20 users | Mean service efficiency | 0.00000056 | 1 | 1 | 0.071 |
| 20 users | Utilization | 0 | 1 | 1 | 0 |
| 40 users | Waiting | -0.04763 ms | 3.51e-11 | 4.22e-14 | -0.534 |
| 40 users | Turnaround | -0.04763 ms | 3.51e-11 | 4.07e-14 | -0.534 |
| 40 users | Completion fairness | 0.00941 | 6.63e-21 | 6.31e-23 | 0.780 |
| 40 users | Service-efficiency fairness | 0.00515 | 3.08e-14 | 1.38e-16 | 0.617 |
| 40 users | Mean service efficiency | 0.00533 | 8.07e-11 | 3.48e-12 | 0.523 |
| 40 users | Utilization | 0.00040 | 1 | 0.233 | 0.053 |
| 60 users | Waiting | -0.24006 ms | 5.98e-28 | 9.13e-24 | -0.943 |
| 60 users | Turnaround | -0.24006 ms | 5.98e-28 | 9.13e-24 | -0.943 |
| 60 users | Completion fairness | 0.02873 | 1.24e-42 | 3.02e-30 | 1.286 |
| 60 users | Service-efficiency fairness | 0.01658 | 5.68e-30 | 1.33e-24 | 0.990 |
| 60 users | Mean service efficiency | 0.01294 | 1.21e-19 | 1.33e-18 | 0.748 |
| 60 users | Utilization | 0.00276 | 0.136 | 0.00779 | 0.157 |

## Interpretation cautions

- At 20 users, differences are negligible; do not overstate the isolated Wilcoxon detections.
- At 40 and 60 users, Priority has lower waiting/turnaround time and higher values on the three listed fairness/efficiency metrics than MLQ.
- Utilization is not significantly different at 40 users; the two tests disagree at 60 users.
- Do not claim that either proposed policy universally outperforms every benchmark.
- Completion fairness is Jain fairness over per-user effective completion rates, not conventional throughput fairness.
- Service-efficiency fairness is Jain fairness over normalized service-efficiency fractions.
- Resource utilization is an abstract workload/makespan packing metric, not physical-layer RF or antenna utilization.
- This project is an abstract event-driven multi-server scheduling model, not a complete physical-layer Massive MIMO simulator.

The full statistical tables, figures, editable MATLAB FIG files, sensitivity results, and combined MAT data are part of the generated local thesis package.

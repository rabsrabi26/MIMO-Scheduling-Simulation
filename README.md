# MIMO Scheduling Simulation — Final Thesis Version

This repository contains the reviewed MATLAB implementation and the final thesis analysis package for a five-policy wireless scheduling comparison.

## Scheduling policies

1. Priority (proposed)
2. Multilevel Queue (proposed)
3. Round Robin
4. Proportional Fair
5. Max C/I

The final Priority configuration uses \`alpha = 0.5\` and \`beta = 0.5\`.

## Experiment configuration

- 16 abstract service resources (one per configured antenna).
- User-load scenarios: 20, 40, and 60 users.
- Final combined dataset: 200 paired Monte Carlo runs per scenario.
- The combined runs are formed from two independent 100-run experiment batches.
- The same generated user/channel scenario is used across all algorithms within a run to support paired comparisons.

## Modelling scope and limitations

This is an **abstract event-driven multi-server wireless scheduling simulation**, not a complete physical-layer Massive MIMO simulator. Each antenna is represented as an independent service resource. The model does not implement per-antenna channel vectors, spatial multiplexing, precoding/combining, antenna correlation, multi-user interference, or post-precoding SINR.

The channel model uses large-scale log-distance path loss and log-normal shadowing to derive a normalized channel-rate factor. The configured bandwidth is not used to calculate a physical-layer system throughput.

## Reported metrics

- **Waiting time:** turnaround time minus actual service time.
- **Turnaround time:** completion time minus arrival time.
- **Completion-rate fairness:** Jain's index over per-user effective completion rates (delivered workload divided by turnaround time); this is not conventional throughput fairness.
- **Service-efficiency fairness:** Jain's index over normalized per-user service-efficiency fractions.
- **Mean service efficiency:** mean of the normalized per-user service-efficiency fractions.
- **Resource utilization:** total service workload divided by the number of resources times the measured makespan. This is an abstract workload/makespan packing measure, not physical RF or antenna utilization.

Waiting time and turnaround time are closely related because turnaround time includes waiting plus service time. Interpret statistical significance alongside confidence intervals and effect sizes; do not claim that either proposed policy universally outperforms every benchmark.

## MATLAB requirements

MATLAB R2021a or newer is recommended. The project uses base MATLAB functionality and Statistics and Machine Learning Toolbox functions for statistical tests and Student-t confidence intervals.

## Reproducing the thesis package

The final combined result files are:

- \`combined_200run_results.mat\`
- \`combined_200run_summary.csv\`
- \`combined_200run_statistical_validation.mat\`
- \`combined_200run_statistical_validation.csv\`

With these files present in the project directory, run:

\`\`\`matlab
RUN_COMPLETE_THESIS_PACKAGE
\`\`\`

This regenerates the six publication-style figures and statistical tables and assembles a timestamped \`Complete_Thesis_Package_*\` folder. It does **not** rerun the Monte Carlo simulations.

To run the underlying 100-run experiment batch from scratch, use \`run_final_experiments.m\`. The independent-seed batch and combined 200-run analysis are handled by their corresponding validation/combination scripts. Only run these when intentionally reproducing the experiments; they are not required to regenerate the final report from the saved combined results.

## Final deliverables

The thesis package contains:
- Six figures (PNG at 300 DPI and editable MATLAB FIG files).
- Descriptive and pairwise statistical tables.
- Paired t-test and Wilcoxon signed-rank results with Holm-adjusted p-values.
- Effect-size information.
- Combined experiment data and sensitivity-analysis outputs.
- The source files used to generate the package.
- A results summary with modelling and interpretation notes.

## Research caution

The scheduler definitions, service-class weights, queue boundaries, and channel-rate abstraction are modelling choices. Ensure they are consistent with the thesis methodology and cited literature, and describe the abstraction and metric definitions explicitly when reporting results.

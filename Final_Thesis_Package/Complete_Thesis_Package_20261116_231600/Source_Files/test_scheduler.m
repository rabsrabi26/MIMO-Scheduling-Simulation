
function test_scheduler()
%TEST_SCHEDULER Validate all five scheduling algorithms.
% This script does not overwrite existing experiment results.

clc;
fprintf("\n========================================\n");
fprintf(" SCHEDULER VALIDATION TESTS\n");
fprintf("========================================\n");

%% TEST 1: Run all five algorithms under contention

cfg = default_config();

cfg.numRuns = 1;
cfg.numUsers = 30;
cfg.numAntennas = 4;
cfg.seed = 20261116;

stream = RandStream("mt19937ar", "Seed", cfg.seed);

users = generate_users(cfg, stream);
ch = calculate_channel(users, cfg, stream);

algorithms = cfg.algorithms;

fprintf("\nTEST 1: Testing all five algorithms\n");

for a = 1:numel(algorithms)

    algorithm = algorithms(a);

    out = scheduler_simulate(users, ch, cfg, algorithm);

    % Check that every user completed.
    assert(all(isfinite(out.completion_ms)), ...
        "%s: Some users did not complete.", algorithm);

    % Check that completion times are after arrivals.
    assert(all(out.completion_ms >= users.arrival_ms - 1e-9), ...
        "%s: Completion occurred before arrival.", algorithm);

    % Check waiting times.
    assert(all(isfinite(out.waiting_ms) & out.waiting_ms >= -1e-9), ...
        "%s: Invalid waiting times.", algorithm);

    % Check turnaround times.
    assert(all(isfinite(out.turnaround_ms) & out.turnaround_ms >= 0), ...
        "%s: Invalid turnaround times.", algorithm);

    % Check fairness range.
    assert(isfinite(out.jainFairness) && ...
        out.jainFairness >= 1/cfg.numUsers - 1e-9 && ...
        out.jainFairness <= 1 + 1e-9, ...
        "%s: Fairness is outside its valid range.", algorithm);

    % Check resource utilization range.
    assert(isfinite(out.resourceUtilization) && ...
        out.resourceUtilization >= 0 && ...
        out.resourceUtilization <= 1, ...
        "%s: Resource utilization is outside [0,1].", algorithm);

    % Check the waiting-time calculation.
    expectedWaiting = out.turnaround_ms - ...
        users.work_ms ./ ch.rateFactor;

    expectedWaiting = max(expectedWaiting, 0);

    assert(max(abs(out.waiting_ms - expectedWaiting)) < 1e-8, ...
        "%s: Waiting-time calculation is inconsistent.", algorithm);

    fprintf("%-20s : PASSED\n", algorithm);

end

%% TEST 2: Verify Round Robin arrival-order behavior

fprintf("\nTEST 2: Round Robin arrival-order test\n");

% Deliberately make user IDs different from arrival order:
% User 2 arrives first, User 3 arrives second, User 1 arrives last.

rrUsers.id = (1:3)';
rrUsers.x_m = zeros(3,1);
rrUsers.y_m = zeros(3,1);
rrUsers.distance_m = [10; 10; 10];

rrUsers.arrival_ms = [2; 0; 1];
rrUsers.service_type = zeros(3,1);
rrUsers.work_ms = [2; 2; 2];

rrCh.rateFactor = ones(3,1);
rrCh.snrLinear = ones(3,1);

rrCfg = default_config();
rrCfg.numAntennas = 1;
rrCfg.rrQuantum_ms = 1;

rrOut = scheduler_simulate( ...
    rrUsers, rrCh, rrCfg, "Round Robin");

expectedCompletion = [6; 2; 5];

assert(max(abs(rrOut.completion_ms - expectedCompletion)) < 1e-8, ...
    "Round Robin failed the arrival-order test.");

fprintf("Round Robin arrival-order test : PASSED\n");

%% TEST 3: Verify deterministic results

fprintf("\nTEST 3: Deterministic execution test\n");

repeatOut = scheduler_simulate( ...
    rrUsers, rrCh, rrCfg, "Round Robin");

assert(max(abs(rrOut.completion_ms - repeatOut.completion_ms)) < 1e-10, ...
    "Round Robin results changed between identical runs.");

fprintf("Deterministic execution test   : PASSED\n");

%% FINAL RESULT

fprintf("\n========================================\n");
fprintf(" ALL SCHEDULER TESTS PASSED\n");
fprintf("========================================\n");

fprintf("\nAll five algorithms completed successfully.\n");
fprintf("Round Robin arrival-order behavior is correct.\n");
fprintf("No existing experiment results were overwritten.\n\n");

end

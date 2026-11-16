
%% RUN_COMPLETE_THESIS_PACKAGE
% Complete thesis package generator.
% Existing simulations are NOT rerun.
% Each generation script runs in an isolated workspace.

clear;
clc;
close all;

%% STEP 1: PROJECT LOCATION

projectDir = fileparts(mfilename('fullpath'));

if isempty(projectDir)
    projectDir = pwd;
end

cd(projectDir);

fprintf('\n====================================================\n');
fprintf('       COMPLETE THESIS PACKAGE GENERATOR\n');
fprintf('====================================================\n');

fprintf('\nProject folder: %s\n', projectDir);

%% STEP 2: CHECK REQUIRED INPUT FILES

requiredFiles = {
    'plot_final_thesis_figures.m'
    'generate_all_thesis_statistical_tables.m'
    'combined_200run_results.mat'
    'combined_200run_statistical_validation.mat'
};

for k = 1:numel(requiredFiles)

    if ~isfile(fullfile(projectDir, requiredFiles{k}))
        error('Required file not found: %s', requiredFiles{k});
    end

end

fprintf('\nAll required files found.\n');

%% STEP 3: CREATE PACKAGE FOLDERS

timestamp = datestr(now, 'yyyymmdd_HHMMSS');

packageDir = fullfile(projectDir, ...
    ['Complete_Thesis_Package_' timestamp]);

figuresDir = fullfile(packageDir, 'Figures');
tablesDir = fullfile(packageDir, 'Tables');
statisticsDir = fullfile(packageDir, 'Statistical_Results');
sensitivityDir = fullfile(packageDir, 'Sensitivity_Analysis');
sourceDir = fullfile(packageDir, 'Source_Files');

mkdir(packageDir);
mkdir(figuresDir);
mkdir(tablesDir);
mkdir(statisticsDir);
mkdir(sensitivityDir);
mkdir(sourceDir);

fprintf('\nPackage folder created:\n%s\n', packageDir);

%% STEP 4: GENERATE FIGURES IN ISOLATED WORKSPACE

fprintf('\n====================================================\n');
fprintf('STEP 1: GENERATING FIGURES\n');
fprintf('====================================================\n');

figureScript = fullfile(projectDir, ...
    'plot_final_thesis_figures.m');

runScriptIsolated(figureScript);

fprintf('\nFigure generation completed.\n');

%% STEP 5: GENERATE TABLES IN ISOLATED WORKSPACE

fprintf('\n====================================================\n');
fprintf('STEP 2: GENERATING STATISTICAL TABLES\n');
fprintf('====================================================\n');

tableScript = fullfile(projectDir, ...
    'generate_all_thesis_statistical_tables.m');

runScriptIsolated(tableScript);

fprintf('\nStatistical table generation completed.\n');

%% STEP 6: COPY FIGURES

fprintf('\n====================================================\n');
fprintf('STEP 3: COPYING FIGURES\n');
fprintf('====================================================\n');

existingFiguresDir = fullfile(projectDir, ...
    'final_thesis_figures');

if isfolder(existingFiguresDir)
    copyfile(existingFiguresDir, figuresDir);
    fprintf('Figures copied successfully.\n');
else
    warning('Figure folder not found.');
end

%% STEP 7: COPY TABLES

fprintf('\n====================================================\n');
fprintf('STEP 4: COPYING TABLES\n');
fprintf('====================================================\n');

existingTablesDir = fullfile(projectDir, ...
    'thesis_statistical_tables');

if isfolder(existingTablesDir)
    copyfile(existingTablesDir, tablesDir);
    fprintf('Tables copied successfully.\n');
else
    warning('Table folder not found.');
end

%% STEP 8: COPY STATISTICAL RESULTS

fprintf('\n====================================================\n');
fprintf('STEP 5: COPYING STATISTICAL RESULTS\n');
fprintf('====================================================\n');

statisticalFiles = {
    'combined_200run_statistical_validation.mat'
    'combined_200run_statistical_validation.csv'
    'final_thesis_statistical_validation.mat'
    'independent_seed_statistical_validation.mat'
    'sensitivity_statistical_validation.mat'
};

for k = 1:numel(statisticalFiles)

    sourceFile = fullfile(projectDir, statisticalFiles{k});

    if isfile(sourceFile)
        copyfile(sourceFile, statisticsDir);
        fprintf('Copied: %s\n', statisticalFiles{k});
    end

end

%% STEP 9: COPY COMBINED EXPERIMENT DATA

fprintf('\n====================================================\n');
fprintf('STEP 6: COPYING EXPERIMENT DATA\n');
fprintf('====================================================\n');

dataFiles = {
    'final_thesis_results.mat'
    'independent_seed_results.mat'
    'combined_200run_results.mat'
    'combined_200run_summary.csv'
};

for k = 1:numel(dataFiles)

    sourceFile = fullfile(projectDir, dataFiles{k});

    if isfile(sourceFile)
        copyfile(sourceFile, statisticsDir);
        fprintf('Copied: %s\n', dataFiles{k});
    end

end

%% STEP 10: COPY SENSITIVITY ANALYSIS

fprintf('\n====================================================\n');
fprintf('STEP 7: COPYING SENSITIVITY ANALYSIS\n');
fprintf('====================================================\n');

existingSensitivityDir = fullfile(projectDir, ...
    'sensitivity_results');

if isfolder(existingSensitivityDir)
    copyfile(existingSensitivityDir, sensitivityDir);
    fprintf('Sensitivity results copied.\n');
else
    fprintf('No sensitivity_results folder found.\n');
end

%% STEP 11: COPY SOURCE CODE

fprintf('\n====================================================\n');
fprintf('STEP 8: COPYING SOURCE CODE\n');
fprintf('====================================================\n');

sourceFiles = {
    'main.m'
    'default_config.m'
    'run_experiment.m'
    'scheduler_simulate.m'
    'generate_users.m'
    'calculate_channel.m'
    'test_scheduler.m'
    'run_final_experiments.m'
    'run_independent_seed_validation.m'
    'validate_final_thesis_results.m'
    'compare_final_priority_vs_mlq.m'
    'combine_and_validate_200_runs.m'
    'plot_final_thesis_figures.m'
    'generate_all_thesis_statistical_tables.m'
    'RUN_COMPLETE_THESIS_PACKAGE.m'
};

for k = 1:numel(sourceFiles)

    sourceFile = fullfile(projectDir, sourceFiles{k});

    if isfile(sourceFile)
        copyfile(sourceFile, sourceDir);
        fprintf('Copied: %s\n', sourceFiles{k});
    end

end

%% STEP 12: CREATE SUMMARY REPORT

fprintf('\n====================================================\n');
fprintf('STEP 9: CREATING SUMMARY REPORT\n');
fprintf('====================================================\n');

summaryFile = fullfile(packageDir, ...
    'Thesis_Results_Summary.txt');

fid = fopen(summaryFile, 'w');

if fid == -1
    error('Could not create summary report.');
end

fprintf(fid, 'COMPLETE THESIS RESULTS PACKAGE\n');
fprintf(fid, '============================================\n\n');

fprintf(fid, 'Generated: %s\n\n', datestr(now));

fprintf(fid, 'EXPERIMENT CONFIGURATION\n');
fprintf(fid, '--------------------------------------------\n');
fprintf(fid, 'Combined Monte Carlo runs per scenario: 200\n');
fprintf(fid, 'User scenarios: 20, 40 and 60\n');
fprintf(fid, 'Antennas: 16\n');
fprintf(fid, 'Priority alpha: 0.5\n');
fprintf(fid, 'Priority beta: 0.5\n\n');

fprintf(fid, 'SCHEDULING ALGORITHMS\n');
fprintf(fid, '--------------------------------------------\n');
fprintf(fid, 'Priority (proposed)\n');
fprintf(fid, 'Multilevel Queue (proposed)\n');
fprintf(fid, 'Round Robin\n');
fprintf(fid, 'Proportional Fair\n');
fprintf(fid, 'Max C/I\n\n');

fprintf(fid, 'OUTPUTS\n');
fprintf(fid, '--------------------------------------------\n');
fprintf(fid, 'Six performance figures.\n');
fprintf(fid, 'Descriptive statistical tables.\n');
fprintf(fid, 'Pairwise comparisons.\n');
fprintf(fid, 'Paired t-tests.\n');
fprintf(fid, 'Wilcoxon signed-rank tests.\n');
fprintf(fid, 'Holm-adjusted p-values.\n');
fprintf(fid, 'Confidence intervals and effect sizes.\n');
fprintf(fid, 'Sensitivity-analysis files, if available.\n\n');

fprintf(fid, 'INTERPRETATION NOTES\n');
fprintf(fid, '--------------------------------------------\n');

fprintf(fid, ['Waiting time and turnaround time are closely ' ...
    'related outcomes.\n\n']);

fprintf(fid, ['Completion fairness is Jain fairness over ' ...
    'per-user effective completion rates, not conventional ' ...
    'throughput fairness.\n\n']);

fprintf(fid, ['Service-efficiency fairness measures fairness ' ...
    'over normalized service-efficiency fractions.\n\n']);

fprintf(fid, ['Resource utilization is an abstract workload ' ...
    'and makespan-based resource-packing measure, not ' ...
    'physical-layer RF efficiency.\n\n']);

fprintf(fid, ['The simulation is an abstract multi-server ' ...
    'wireless scheduling model, not a complete Massive MIMO ' ...
    'physical-layer simulation.\n\n']);

fprintf(fid, ['Statistical significance should be considered ' ...
    'alongside effect sizes and practical importance.\n\n']);

fprintf(fid, 'END OF REPORT\n');

fclose(fid);

fprintf('Summary report created.\n');

%% STEP 13: FINAL MESSAGE

fprintf('\n====================================================\n');
fprintf(' COMPLETE THESIS PACKAGE GENERATION FINISHED\n');
fprintf('====================================================\n');

fprintf('\nOutput folder:\n%s\n', packageDir);

fprintf('\nContents:\n');
fprintf('1. Figures\n');
fprintf('2. Tables\n');
fprintf('3. Statistical results\n');
fprintf('4. Sensitivity analysis\n');
fprintf('5. Source code\n');
fprintf('6. Summary report\n');

fprintf('\n====================================================\n');

%% LOCAL FUNCTION
% This function gives each existing script its own workspace.
% A clear command inside that script cannot erase the master
% script's variables.

function runScriptIsolated(scriptPath)

    run(scriptPath);

end

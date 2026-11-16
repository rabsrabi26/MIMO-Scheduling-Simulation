%% RUN_COMPLETE_THESIS_PACKAGE
% Rebuilds the thesis report from saved combined results.
% Does not rerun Monte Carlo simulations.

clear; clc; close all;
projectDir=fileparts(mfilename('fullpath'));
if isempty(projectDir), projectDir=pwd; end
cd(projectDir);

fprintf('\n====================================================\n');
fprintf('       COMPLETE THESIS PACKAGE GENERATOR\n');
fprintf('====================================================\n');
fprintf('\nProject folder: %s\n',projectDir);

requiredFiles={'plot_final_thesis_figures.m', ...
    'generate_all_thesis_statistical_tables.m', ...
    'combined_200run_results.mat', ...
    'combined_200run_statistical_validation.mat'};
for k=1:numel(requiredFiles)
    if ~isfile(fullfile(projectDir,requiredFiles{k}))
        error('Required file not found: %s',requiredFiles{k});
    end
end

timestamp=datestr(now,'yyyymmdd_HHMMSS');
packageDir=fullfile(projectDir,['Complete_Thesis_Package_' timestamp]);
figuresDir=fullfile(packageDir,'Figures');
tablesDir=fullfile(packageDir,'Tables');
statisticsDir=fullfile(packageDir,'Statistical_Results');
sensitivityDir=fullfile(packageDir,'Sensitivity_Analysis');
sourceDir=fullfile(packageDir,'Source_Files');
mkdir(figuresDir); mkdir(tablesDir); mkdir(statisticsDir);
mkdir(sensitivityDir); mkdir(sourceDir);

fprintf('\nSTEP 1: GENERATING FIGURES\n');
runScriptIsolated(fullfile(projectDir,'plot_final_thesis_figures.m'));

fprintf('\nSTEP 2: GENERATING STATISTICAL TABLES\n');
runScriptIsolated(fullfile(projectDir,'generate_all_thesis_statistical_tables.m'));

fprintf('\nSTEP 3: COPYING FIGURES\n');
copyIfFolder(fullfile(projectDir,'final_thesis_figures'),figuresDir);

fprintf('\nSTEP 4: COPYING TABLES\n');
copyIfFolder(fullfile(projectDir,'thesis_statistical_tables'),tablesDir);

fprintf('\nSTEP 5: COPYING STATISTICAL RESULTS\n');
statisticalFiles={'combined_200run_statistical_validation.mat', ...
    'combined_200run_statistical_validation.csv', ...
    'final_thesis_statistical_validation.mat', ...
    'independent_seed_statistical_validation.mat'};
for k=1:numel(statisticalFiles)
    copyIfFile(fullfile(projectDir,statisticalFiles{k}),statisticsDir);
end

fprintf('\nSTEP 6: COPYING COMBINED EXPERIMENT DATA\n');
dataFiles={'combined_200run_results.mat','combined_200run_summary.csv'};
for k=1:numel(dataFiles)
    copyIfFile(fullfile(projectDir,dataFiles{k}),statisticsDir);
end

fprintf('\nSTEP 7: COPYING SENSITIVITY ANALYSIS\n');
copyIfFolder(fullfile(projectDir,'sensitivity_results'),sensitivityDir);

fprintf('\nSTEP 8: COPYING SOURCE CODE\n');
sourceFiles={'main.m','default_config.m','run_experiment.m', ...
    'scheduler_simulate.m','generate_users.m','calculate_channel.m', ...
    'test_scheduler.m','run_final_experiments.m', ...
    'validate_final_thesis_results.m','compare_final_priority_vs_mlq.m', ...
    'combine_and_validate_200_runs.m','plot_final_thesis_figures.m', ...
    'generate_all_thesis_statistical_tables.m', ...
    'RUN_COMPLETE_THESIS_PACKAGE.m'};
for k=1:numel(sourceFiles)
    copyIfFile(fullfile(projectDir,sourceFiles{k}),sourceDir);
end

fprintf('\nSTEP 9: CREATING SUMMARY REPORT\n');
summaryPath=fullfile(packageDir,'Thesis_Results_Summary.txt');
fid=fopen(summaryPath,'w');
if fid<0, error('Could not create summary report.'); end
fprintf(fid,'COMPLETE THESIS RESULTS PACKAGE\n');
fprintf(fid,'================================\n\n');
fprintf(fid,'Generated: %s\n\n',datestr(now));
fprintf(fid,'EXPERIMENT CONFIGURATION\n');
fprintf(fid,'Combined Monte Carlo runs per scenario: 200\n');
fprintf(fid,'User scenarios: 20, 40 and 60\n');
fprintf(fid,'Antennas: 16 abstract service resources\n');
fprintf(fid,'Priority alpha: 0.5\nPriority beta: 0.5\n\n');
fprintf(fid,'SCHEDULING ALGORITHMS\n');
fprintf(fid,'Priority (proposed)\nMultilevel Queue (proposed)\n');
fprintf(fid,'Round Robin\nProportional Fair\nMax C/I\n\n');
fprintf(fid,'OUTPUTS\nSix performance figures; descriptive and pairwise tables;\n');
fprintf(fid,'paired t-tests; Wilcoxon signed-rank tests; Holm-adjusted p-values;\n');
fprintf(fid,'confidence intervals; effect sizes; sensitivity-analysis outputs.\n\n');
fprintf(fid,'INTERPRETATION NOTES\n');
fprintf(fid,'Waiting and turnaround time are closely related outcomes.\n');
fprintf(fid,'Completion fairness is Jain fairness over per-user effective completion rates, not conventional throughput fairness.\n');
fprintf(fid,'Service-efficiency fairness is Jain fairness over normalized service-efficiency fractions.\n');
fprintf(fid,'Resource utilization is an abstract workload/makespan metric, not physical-layer RF efficiency.\n');
fprintf(fid,'This is an abstract multi-server scheduling model, not a complete Massive MIMO physical-layer simulation.\n');
fprintf(fid,'Interpret statistical significance alongside effect sizes and practical importance.\n');
fclose(fid);

fprintf('\n====================================================\n');
fprintf(' COMPLETE THESIS PACKAGE GENERATION FINISHED\n');
fprintf('====================================================\n');
fprintf('Output folder:\n%s\n',packageDir);
fprintf('\nNo simulations were rerun.\nNo original results were modified.\n');

function runScriptIsolated(scriptPath)
    run(scriptPath);
end

function copyIfFile(sourcePath,destinationFolder)
    if isfile(sourcePath)
        copyfile(sourcePath,destinationFolder);
        fprintf('Copied: %s\n',sourcePath);
    else
        warning('Optional file not found: %s',sourcePath);
    end
end

function copyIfFolder(sourcePath,destinationFolder)
    if isfolder(sourcePath)
        copyfile(sourcePath,destinationFolder);
        fprintf('Copied folder: %s\n',sourcePath);
    else
        warning('Optional folder not found: %s',sourcePath);
    end
end

%RUN_LEACH_METRICS_EXPERIMENTS Repeated LEACH baseline evaluation.
% Requires WSN.m and metrics helper functions in the MATLAB current folder.
% No changes to IDE.m or fitness functions.
numTrials = 20;
numRounds = 100;
trialsCell = cell(1,numTrials);
for t = 1:numTrials
    fprintf('LEACH trial %d/%d (seed %d)\n',t,numTrials,t);
    trialsCell{t} = run_leach_metrics_trial(numRounds,t);
end
trials = [trialsCell{:}];
[trialSummary, meanCurves] = analyze_wsn_trials(trials,'LEACH');
plot_wsn_trial_statistics(meanCurves,'LEACH');
save('LEACH_trial_data.mat','trials','trialSummary','meanCurves');
fprintf('Done: LEACH_trial_results.csv, LEACH_summary.csv, LEACH_mean_curves.csv\n');

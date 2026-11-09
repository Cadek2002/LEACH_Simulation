function [summary, curves] = analyze_wsn_trials(trials, outputPrefix)
%ANALYZE_WSN_TRIALS Summarize multiple equal-length WSN metric structs.
% NaN lifetime milestones indicate not observed; excluded from milestone mean.
if nargin < 2 || isempty(outputPrefix), outputPrefix = 'LEACH'; end
assert(~isempty(trials), 'Supply at least one metrics struct.');
if iscell(trials), trials = [trials{:}]; end
n = numel(trials);
fields = {'aliveNodes','residualEnergyJ','avgResidualEnergyJ', ...
    'energyConsumedPerRoundJ','cumulativeEnergyConsumedJ', ...
    'packetsAtBSPerRound','packetsAtBSCumulative'};
R = numel(trials(1).rounds);
curves = struct(); curves.rounds = trials(1).rounds(:);
for j = 1:numel(fields)
    f = fields{j}; A = nan(R, n);
    for i = 1:n
        assert(numel(trials(i).rounds) == R, 'Trials must have equal lengths.');
        v = trials(i).(f);
        A(:,i) = v(:);
    end
    curves.(f).mean = mean(A, 2, 'omitnan');
    curves.(f).std = std(A, 0, 2, 'omitnan');
end
seeds = nan(n,1); FND = nan(n,1); HND = nan(n,1); LND = nan(n,1);
finalAlive = nan(n,1); finalEnergy = nan(n,1); totalPackets = nan(n,1);
for i = 1:n
    if isfield(trials, 'seed'), seeds(i) = trials(i).seed; end
    FND(i) = trials(i).FND; HND(i) = trials(i).HND; LND(i) = trials(i).LND;
    finalAlive(i) = trials(i).aliveNodes(end);
    finalEnergy(i) = trials(i).residualEnergyJ(end);
    totalPackets(i) = trials(i).packetsAtBSCumulative(end);
end
perTrial = table(seeds,FND,HND,LND,finalAlive,finalEnergy,totalPackets, ...
    'VariableNames', {'Seed','FND','HND','LND','FinalAliveNodes', ...
                      'FinalResidualEnergyJ','CumulativePacketsAtBS'});
writetable(perTrial, [outputPrefix '_trial_results.csv']);
metricNames = {'FND';'HND';'LND';'FinalAliveNodes'; ...
               'FinalResidualEnergyJ';'CumulativePacketsAtBS'};
values = [FND,HND,LND,finalAlive,finalEnergy,totalPackets];
means = mean(values,1,'omitnan')';
sds = std(values,0,1,'omitnan')';
observed = sum(~isnan(values),1)';
summary = table(metricNames,means,sds,observed, ...
    'VariableNames',{'Metric','Mean','StdDev','ObservedTrials'});
writetable(summary,[outputPrefix '_summary.csv']);
curveTable = table(curves.rounds,'VariableNames',{'Round'});
for j = 1:numel(fields)
    f = fields{j};
    curveTable.([f '_Mean']) = curves.(f).mean;
    curveTable.([f '_StdDev']) = curves.(f).std;
end
writetable(curveTable,[outputPrefix '_mean_curves.csv']);
disp(summary);
end

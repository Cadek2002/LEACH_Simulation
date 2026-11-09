function plot_wsn_trial_statistics(curves, protocol)
%PLOT_WSN_TRIAL_STATISTICS Plot mean and +/- one standard deviation.
if nargin < 2, protocol = 'LEACH'; end
fields = {'aliveNodes','residualEnergyJ','packetsAtBSCumulative', ...
          'energyConsumedPerRoundJ'};
labels = {'Alive nodes','Residual energy (J)', ...
          'Cumulative packets at BS (approx.)','Energy consumed per round (J)'};
for j = 1:numel(fields)
    f = fields{j}; mu = curves.(f).mean; sd = curves.(f).std;
    x = curves.rounds;
    figure('Name',[protocol ' - ' labels{j}]); hold on; grid on;
    fill([x;flipud(x)], [mu-sd;flipud(mu+sd)], [0.75 0.83 0.95], ...
        'FaceAlpha',0.35,'EdgeColor','none','DisplayName','Mean +/- 1 SD');
    plot(x,mu,'b','LineWidth',1.7,'DisplayName','Mean');
    xlabel('Simulation round'); ylabel(labels{j});
    title([protocol ': ' labels{j}]); legend('Location','best');
end
end

function plot_wsn_metrics(varargin)
%PLOT_WSN_METRICS Plot one or more metrics structs from collect_wsn_metrics.
assert(nargin >= 1, 'Supply at least one metrics struct.');
fields = {'aliveNodes','residualEnergyJ','packetsAtBSCumulative', ...
    'avgResidualEnergyJ','energyConsumedPerRoundJ', ...
    'cumulativeEnergyConsumedJ'};
labels = {'Alive nodes','Total residual energy (J)', ...
    'Cumulative packets received at BS', ...
    'Average residual energy per alive node (J)', ...
    'Energy consumed per round (J)', ...
    'Cumulative energy consumption (J)'};
for j = 1:numel(fields)
    figure('Name', labels{j}); hold on; grid on;
    for i = 1:nargin
        m = varargin{i};
        y = m.(fields{j});
        if all(isnan(y)), continue; end
        plot(m.rounds, y, 'LineWidth', 1.5, 'DisplayName', m.protocol);
    end
    xlabel('Simulation round'); ylabel(labels{j}); title(labels{j});
    if ~isempty(findobj(gca,'Type','line')), legend('Location','best'); end
end
end

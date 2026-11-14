function plot_wsn_metrics(varargin)
%PLOT_WSN_METRICS Plot one or more metrics structs or struct arrays.
assert(nargin >= 1, 'Supply at least one metrics struct or struct array.');

% Flatten inputs to handle individual structs, separate arguments, 
% or multi-protocol struct arrays alike.
metricsList = {};
for i = 1:nargin
    arg = varargin{i};
    for k = 1:numel(arg)
        metricsList{end+1} = arg(k); %#ok<AGROW>
    end
end
assert(~isempty(metricsList), 'Supply at least one valid metrics struct.');

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
    for i = 1:numel(metricsList)
        m = metricsList{i};
        y = m.(fields{j});
        if all(isnan(y)), continue; end
        plot(m.rounds, y, 'LineWidth', 1.5, 'DisplayName', m.protocol);
    end
    xlabel('Simulation round'); ylabel(labels{j}); title(labels{j});
    if ~isempty(findobj(gca,'Type','line')), legend('Location','best'); end
end
end

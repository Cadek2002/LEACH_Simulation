function export_wsn_metrics(metrics, filename)
%EXPORT_WSN_METRICS Write one or more protocol metrics structs to CSV.
%   metrics can be a single metrics struct or a multi-protocol struct array in case we want to do some single-ptotocol testing.

    if nargin < 2
        if numel(metrics) == 1
            filename = [metrics(1).protocol '_metrics.csv'];
        else
            filename = 'wsn_metrics_combined.csv';
        end
    end

    T_all = table();

    for i = 1:numel(metrics)
        m = metrics(i);
        nRounds = numel(m.rounds);
        
        % Repeat prot name for number of rounds
        protCol = repmat({char(m.protocol)}, nRounds, 1);

        T = table(protCol, m.rounds, m.aliveNodes, m.residualEnergyJ, ...
            m.avgResidualEnergyJ, ...
            m.energyConsumedPerRoundJ, ...
            m.cumulativeEnergyConsumedJ, ...
            m.packetsAtBSPerRound, m.packetsAtBSCumulative, ...
            'VariableNames', {'Protocol', 'Round','AliveNodes','ResidualEnergyJ', ...
            'AvgResidualEnergyJ', ...
            'EnergyConsumedPerRoundJ', ...
            'CumulativeEnergyConsumedJ', ...
            'PacketsAtBS','CumulativePacketsAtBS'});
            
        T_all = [T_all; T];
    end

    writetable(T_all, filename);
end
function penalty = residualEnergyFactor(VCH_positions, nodes, E_init, mu)

    numVCH = size(VCH_positions, 1);
    numNodes = numel(nodes);

    selectedNodes = [];

    energies = [nodes.E];
    aliveNodes = find(energies > 0);

    for i = 1:numVCH

        distances = hypot( ...
            [nodes.x] - VCH_positions(i, 1), ...
            [nodes.y] - VCH_positions(i, 2));


        denom = max(distances) / max(min(distances), eps);

        if denom == 0
            denom = 1;
        end

        priorities = mu * ((max(distances) - distances) / denom) ...
                   + (1 - mu) * (energies / E_init);

                candidateIdx = setdiff(aliveNodes, selectedNodes);

        if isempty(candidateIdx)
            break;
        end

        [~, localMax] = max(priorities(candidateIdx));

        maxIndex = candidateIdx(localMax);

        selectedNodes = [selectedNodes, maxIndex];

    end

    if isempty(selectedNodes)
        penalty = 1;
    else
        selectedEnergies = energies(selectedNodes);

        penalty = 1 - mean(selectedEnergies / E_init);
    end

end
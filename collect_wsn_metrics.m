function metricsArray = collect_wsn_metrics(histories, packetsAtBSList, protocols)
%COLLECT_WSN_METRICS Collect round-level network performance for multiple WSN protocols.
%   histories: cell array where each element is a cell array of WSN snapshots.
%   packetsAtBSList: cell array where each element is the packetsAtBS vector for that protocol.
%   protocols: cell array of descriptive labels (e.g., {'LEACH', 'CRPIDE'}).

    if nargin < 3 || isempty(protocols)
        protocols = arrayfun(@(i) sprintf('Protocol %d', i), 1:numel(histories), 'UniformOutput', false);
    end
    if nargin < 2 || isempty(packetsAtBSList)
        packetsAtBSList = cell(size(histories));
    end
    
    nProtocols = numel(histories);
    % Preallocate struct array with identical fields
    metricsArray = [];

    for p = 1:nProtocols
        h = histories{p};
        
        % Handle optional/empty packet vectors for individual protocols
        if p <= numel(packetsAtBSList) && ~isempty(packetsAtBSList{p})
            pBS = packetsAtBSList{p};
        else
            pBS = [];
        end
        
        prot = protocols{p};
        
        % Call your single-protocol function
        singleMetrics = collect_wsn_metrics_single(h, pBS, prot);
        
        % Accumulate into an array of structs
        if p == 1
            metricsArray = singleMetrics;
        else
            metricsArray(p) = singleMetrics;
        end
    end
end


function metrics = collect_wsn_metrics_single(history, packetsAtBS, protocol)
%COLLECT_WSN_METRICS Collect round-level network performance from WSN snapshots.
% history: cell array of WSN objects, one snapshot per completed round.
% packetsAtBS: vector of successfully delivered BS packets PER ROUND.
%              Use NaN for rounds without instrumented delivery counts.
% protocol: descriptive label (e.g. 'LEACH' or 'CRPIDE').
if nargin < 3 || isempty(protocol), protocol = 'WSN'; end
nRounds = numel(history);
if nargin < 2 || isempty(packetsAtBS), packetsAtBS = nan(nRounds,1); end
packetsAtBS = packetsAtBS(:);
assert(numel(packetsAtBS) == nRounds, 'Packet count must have one value per round.');
alive = zeros(nRounds,1);
residual = zeros(nRounds,1);
for r = 1:nRounds
    assert(~isempty(history{r}), 'Missing network snapshot at round %d.', r);
    energies = [history{r}.nodes.E];
    alive(r) = nnz(energies > 0);
    residual(r) = sum(max(0, energies));
end

% Average residual energy among alive nodes
avgEnergy = zeros(nRounds,1);

for r = 1:nRounds
    if alive(r) > 0
        avgEnergy(r) = residual(r) / alive(r);
    end
end

% Initial total network energy
initialEnergies = [history{1}.nodes.E];
initialTotalEnergy = numel(initialEnergies) * history{1}.E_init;

% Cumulative energy consumed
cumulativeEnergyConsumed = max(0, initialTotalEnergy - residual);

% Energy consumed during each round
energyConsumedPerRound = [initialTotalEnergy; residual(1:end-1)] ...
    - residual;

nNodes = numel(history{1}.nodes);
first = find(alive < nNodes, 1, 'first');
half = find(alive <= floor(nNodes/2), 1, 'first');
last = find(alive == 0, 1, 'first');
% NaN means the event was not observed within the simulated rounds.
if isempty(first), first = NaN; end
if isempty(half), half = NaN; end
if isempty(last), last = NaN; end
rounds = (1:nRounds)';
metrics = struct('protocol',char(protocol), 'rounds',rounds, ...
    'aliveNodes',alive, 'residualEnergyJ',residual, ...
    'avgResidualEnergyJ',avgEnergy, ...
    'energyConsumedPerRoundJ',energyConsumedPerRound, ...
    'cumulativeEnergyConsumedJ',cumulativeEnergyConsumed, ...
    'packetsAtBSPerRound',packetsAtBS, ...
    'packetsAtBSCumulative',cumsum(packetsAtBS), ...
    'FND',first, 'HND',half, 'LND',last);
end

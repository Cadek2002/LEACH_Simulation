function metrics = collect_wsn_metrics(history, packetsAtBS, protocol)
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

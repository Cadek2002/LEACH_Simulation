function metrics = run_leach_metrics_trial(numRounds, seed)
%RUN_LEACH_METRICS_TRIAL Run one LEACH baseline trial without opening figures.
% Uses the same model/parameters as wsn_LEACH_with_metrics.m.
% Packet count is an approximation: successful CH-to-BS transmissions only.
if nargin < 1 || isempty(numRounds), numRounds = 100; end
if nargin < 2 || isempty(seed), seed = 1; end
validateattributes(numRounds, {'numeric'}, {'scalar','integer','positive'});
rng(seed, 'twister');
net = WSN();
net.N = 100; net.field_width = 400; net.field_height = 400;
net.E_init = 0.5; net.initial_energy = net.E_init;
net.k_data = 5000; net.E_DA = 5e-9; net.P = 0.05;
net.Round = 1; net.Sensor_Range = hypot(net.field_height, net.field_width);
net.generate_wsn_topology();
history = cell(numRounds, 1);
packetsAtBS = zeros(numRounds, 1);
for r = 1:numRounds
    net.Round = r;
    net.LEACH_Clustering();
    % Assign living member nodes to the closest living CH.
    livingCH = net.ch_indices([net.nodes(net.ch_indices).E] > 0);
    for i = 1:net.N
        if ~strcmp(net.nodes(i).role, 'MEMBER') || net.nodes(i).E <= 0 || isempty(livingCH)
            net.nodes(i).cluster_head_id = 0;
            continue;
        end
        d = arrayfun(@(j) hypot(net.nodes(i).x-net.nodes(j).x, ...
                                   net.nodes(i).y-net.nodes(j).y), livingCH);
        [~, k] = min(d);
        net.nodes(i).cluster_head_id = livingCH(k);
    end
    for i = 1:net.N
        ch = net.nodes(i).cluster_head_id;
        if ~strcmp(net.nodes(i).role, 'MEMBER') || net.nodes(i).E <= 0 || ch <= 0
            continue;
        end
        if net.nodes(ch).E <= 0, continue; end
        [tx, rx, ~] = net.send_packet(net.nodes(i), net.nodes(ch), net.k_data);
        net.nodes(i).E = tx.E;
        net.nodes(ch).E = rx.E;
    end
    for ch = net.ch_indices
        if net.nodes(ch).E <= 0, continue; end
        members = sum([net.nodes.cluster_head_id] == ch & ...
                      strcmp({net.nodes.role}, 'MEMBER'));
        Eagg = (members + 1) * net.k_data * net.E_DA;
        net.nodes(ch).E = max(0, net.nodes(ch).E - Eagg);
        if net.nodes(ch).E <= 0, continue; end
        [tx, ~, isDead] = net.send_packet(net.nodes(ch), net.BS, net.k_data);
        if ~isDead, packetsAtBS(r) = packetsAtBS(r) + 1; end
        net.nodes(ch).E = tx.E;
    end
    history{r} = copy(net);
end
metrics = collect_wsn_metrics(history, packetsAtBS, 'LEACH');
metrics.seed = seed;
end

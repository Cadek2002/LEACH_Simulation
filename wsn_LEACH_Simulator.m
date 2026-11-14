import WSN.*
import IDE.*

function [history, packets_received] = run_CRPIDE(net, ide, num_rounds, IDE_Interval)

packets_received = zeros([num_rounds, 1]);
history = cell(1, num_rounds);
ide.run(net, 200, 50, 20)
for r = 1:num_rounds
    net.Round = r;


    %run IDE every x rounds
    if IDE_Interval > 0 && mod(r-1, IDE_Interval) == 0

        ide.run(net, 50, 50, 20)
        % disp(ide.top_member)
        % 
        % progress = (net.Round - 1) / max(num_rounds - 1, 1);
        % 
        % VCH_positions = reshape(ide.top_member_vector, 2, []).';
        % 
        % f4 = multiHopCandidacy(VCH_positions, net.BS);
        % 
        % f5 = residualEnergyFactor( ...
        %     VCH_positions, net.nodes, net.E_init, ide.mu);
        % 
        % dynamicEnergy = progress * f5;
        % 
        % fprintf('Round %d: f4 = %.4f, f5 = %.4f, Dynamic Energy = %.4f\n', ...
        %     r, f4, f5, dynamicEnergy);

    end


    % Clustering Algo
    %net.CRPIDE_Clustering(ide);



    net.CRPIDE_Clustering(ide);
    net.CRPIDE_ClusterAssignment(ide);

    % if any([net.nodes(net.ch_indices).E] <= 0)
    %     error('A dead node was selected as a cluster head!');
    % else
    %     %disp('CH check passed: all selected cluster heads are alive.');
    % end

    %Member Nodes send data to cluster heads
    net.execute_member_assignment()

    %Build CH transmission plan and execute
    transmission_plan = net.CRPIDE_Transmission_Plan(ide);
    packets_received(r) = net.execute_transmission_plan(transmission_plan);
    %save net state to history
    history{r} = copy(net);
end

end

%womp womp
clear; clc; close all;


net = WSN();

%% WSN Network Setup
net.N = 100;                 % Total nodes
net.field_width = 200;             % Field width (meters)
net.field_height = 200;            % Field height (meters)
net.E_init = 0.5;          % Initial energy (Joules)
net.k_data = 5000;        % Data packet size (bits)
net.E_DA = 5e-9;             % Data Aggregation Energy (5 nJ/bit/signal)
net.P = .05;                 % Desired portion of CHs
net.Round = 1;               % Current Round
net.Sensor_Range = 80; % Sensor range, default to max
num_rounds = 1500;

% Topo func (currently a random rectangle with BS at center
net.generate_wsn_topology();

CRP_ide = IDE();
CRP_ide.maxRounds = num_rounds;
CRP_ide.delta = 0;
CRP_ide.epsilon = 0;
CRPIDE_net = net.copy();

[CRPIDE_history, CRPIDE_packets_received] = run_CRPIDE(CRPIDE_net, CRP_ide, num_rounds, -1);


CRPIDE_Enhanced_ide = IDE();
CRPIDE_Enhanced_ide.maxRounds = num_rounds;
CRPIDE_Enhanced_ide.alpha = .18;
CRPIDE_Enhanced_ide.beta = .18;
CRPIDE_Enhanced_ide.gamma = .29;
CRPIDE_Enhanced_ide.delta = .15;
CRPIDE_Enhanced_ide.epsilon = .1;

CRPIDE_Enhanced_net = net.copy();


[CRPIDE_Enhanced_history, CRPIDE_Enhanced_packets_received] = run_CRPIDE(CRPIDE_Enhanced_net, CRPIDE_Enhanced_ide, num_rounds, 50);



%net.Copy()
net.visualize_WSN_history(CRPIDE_Enhanced_history)

% Metrics after the complete LEACH simulation
leachMetrics = collect_wsn_metrics({CRPIDE_history, CRPIDE_Enhanced_history}, {CRPIDE_packets_received, CRPIDE_Enhanced_packets_received}, {'CRPIDE', 'CRPIDE Enhanced'});
export_wsn_metrics(leachMetrics, 'CRPIDE_metrics.csv');
plot_wsn_metrics(leachMetrics);
fprintf('FND: %g, HND: %g, LND: %g (NaN = not reached)\n', ...
    leachMetrics.FND, leachMetrics.HND, leachMetrics.LND);

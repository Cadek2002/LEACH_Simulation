import WSN.*
import IDE.*



%womp womp
clear; clc; close all;


net = WSN();

%% WSN Network Setup
net.N = 100;                 % Total nodes
net.field_width = 100;             % Field width (meters)
net.field_height = 100;            % Field height (meters)
net.E_init = 0.5;          % Initial energy (Joules)
net.k_data = 5000;        % Data packet size (bits)
net.E_DA = 5e-9;             % Data Aggregation Energy (5 nJ/bit/signal)
net.P = .05;                 % Desired portion of CHs
net.Round = 1;               % Current Round
net.Sensor_Range = 20; % Sensor range, default to max


% Topo func (currently a random rectangle with BS at center
net.generate_wsn_topology();

num_rounds = 1000;
IDE_Interval = 1010;
packets_received = zeros([num_rounds, 1]);

history = cell(1, num_rounds);

ide = IDE();
ide.maxRounds = num_rounds;
%ide.run(net, 200, 50, 20)
%disp(ide.top_member)



%net.Copy()

for r = 1:num_rounds
    net.Round = r;

    %run IDE every x rounds
    if mod(r-1, IDE_Interval) == 0

        ide.run(net, 100, 50, 20)
        disp(ide.top_member)
    
        progress = (net.Round - 1) / max(num_rounds - 1, 1);
    
        VCH_positions = reshape(ide.top_member_vector, 2, []).';
    
        f4 = multiHopCandidacy(VCH_positions, net.BS);
    
        f5 = residualEnergyFactor( ...
            VCH_positions, net.nodes, net.E_init, ide.mu);
    
        dynamicEnergy = progress * f5;
    
        fprintf('Round %d: f4 = %.4f, f5 = %.4f, Dynamic Energy = %.4f\n', ...
            r, f4, f5, dynamicEnergy);

    end
    % % Clustering Algo
    % net.LEACH_Clustering();



    % %assign each member node to its closest CH
    % net.LEACH_Clustering();
    % net.LEACH_ClusterAssignment();


    % Clustering Algo
    %net.CRPIDE_Clustering(ide);



    net.CRPIDE_Clustering(ide);
    net.CRPIDE_ClusterAssignment(ide);

    if any([net.nodes(net.ch_indices).E] <= 0)
        error('A dead node was selected as a cluster head!');
    else
        %disp('CH check passed: all selected cluster heads are alive.');
    end



    %Member Nodes send data to cluster heads
    for i = 1:net.N
        if strcmp(net.nodes(i).role, 'MEMBER') && net.nodes(i).E > 0
            ch_idx = net.nodes(i).cluster_head_id;
            
            % Store current state of member and assigned CH
            tx = net.nodes(i);
            if ch_idx ~= -1
                rx = net.nodes(ch_idx);
            else
                rx = net.BS;
            end
            
            % Transmit packet from member to CH
            [tx_updated, rx_updated, ~] = net.send_packet(tx, rx, net.k_data);
            
            % Update new Energy for node and CH to receive
            net.nodes(i).E = tx_updated.E;
            if ch_idx ~= -1
                net.nodes(ch_idx).E = rx_updated.E;
            end
        end
    end

    %Build CH transmission plan and execute
    transmission_plan = net.CRPIDE_Transmission_Plan(ide);
    packets_received(r) = net.execute_transmission_plan(transmission_plan);
    

    
    %send to BS
    % for ch_idx = net.ch_indices
    %     if net.nodes(ch_idx).E > 0
    %         % Count connected cluster members
    %         cluster_members = sum([net.nodes.cluster_head_id] == ch_idx & strcmp({net.nodes.role}, 'MEMBER'));
    % 
    %         % Compression cost
    %         E_agg = (cluster_members + 1) * net.k_data * net.E_DA;
    %         net.nodes(ch_idx).E = max(0, net.nodes(ch_idx).E - E_agg);
    % 
    %         % Transmit to BS
    %         [tx_updated, ~, ~] = net.send_packet(net.nodes(ch_idx), net.BS, net.k_data);
    %         net.nodes(ch_idx).E = tx_updated.E;
    %     end
    % end
    history{r} = copy(net);
end

net.visualize_WSN_history(history)

% Metrics after the complete LEACH simulation
leachMetrics = collect_wsn_metrics(history, packets_received, 'LEACH');
export_wsn_metrics(leachMetrics, 'LEACH_metrics.csv');
plot_wsn_metrics(leachMetrics);
fprintf('FND: %g, HND: %g, LND: %g (NaN = not reached)\n', ...
    leachMetrics.FND, leachMetrics.HND, leachMetrics.LND);

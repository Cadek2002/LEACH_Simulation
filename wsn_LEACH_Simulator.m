import WSN.*
import IDE.*



%womp womp
clear; clc; close all;


net = WSN();

%% WSN Network Setup
net.N = 100;                 % Total nodes
net.field_width = 400;             % Field width (meters)
net.field_height = 400;            % Field height (meters)
net.E_init = 0.5;          % Initial energy (Joules)
net.k_data = 5000;        % Data packet size (bits)
net.E_DA = 5e-9;             % Data Aggregation Energy (5 nJ/bit/signal)
net.P = .05;                 % Desired portion of CHs
net.Round = 1;               % Current Round
net.Sensor_Range = hypot(net.field_height, net.field_width); % Sensor range, default to max

% Topo func (currently a random rectangle with BS at center
net.generate_wsn_topology();

num_rounds = 40;
history = cell(1, num_rounds);

ide = IDE();
ide.run(net, 100, 10)
disp(ide.top_member)

net.Copy()

for r = 1:num_rounds
    net.Round = r;
    % % Clustering Algo
    % net.LEACH_Clustering();
    % 
    % 
    % 
    % %assign each member node to its closest CH
    % net.LEACH_Clustering();
    % net.LEACH_ClusterAssignment();


    % Clustering Algo
    net.CRPIDE_Clustering(ide);



    %assign each member node to its closest CH
    net.CRPIDE_Clustering();
    net.CRPIDE_ClusterAssignment();



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
    transmission_plan = net.LEACH_Transmission_Plan();
    net.execute_transmission_plan(transmission_plan);
    
    % % CHs agg and send to BS
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

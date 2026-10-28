import WSN.*



%womp womp
clear; clc; close all;


net = WSN();

%% WSN Network Setup
net.N = 100;                 % Total nodes
net.width = 400;             % Field width (meters)
net.height = 400;            % Field height (meters)
net.E_init = 0.5;          % Initial energy (Joules)
net.k_data = 5000;        % Data packet size (bits)
net.E_DA = 5e-9;             % Data Aggregation Energy (5 nJ/bit/signal)
net.P = .05;                 % Desired portion of CHs
net.Round = 1;               % Current Round
net.Sensor_Range = hypot(net.height, net.width); % Sensor range, default to max

% Topo func (currently a random rectangle with BS at center
net.generate_wsn_topology();

num_rounds = 40;
history = cell(1, num_rounds);

for r = 1:num_rounds
    net.Round = r;
    % Clustering Algo
    net.LEACH_Clustering();
    
    
    % Assign each member node to its closest CH
    for i = 1:net.N
        if strcmp(net.nodes(i).role, 'MEMBER')
            min_dist = Inf;
            closest_ch = 0;
            for ch_idx = net.ch_indices
                d = sqrt((net.nodes(i).x - net.nodes(ch_idx).x)^2 + (net.nodes(i).y - net.nodes(ch_idx).y)^2);
                if d < min_dist
                    min_dist = d;
                    closest_ch = ch_idx;
                end
            end
            net.nodes(i).cluster_head_id = closest_ch;
        end
    end
    
    %% Member nodes transmit to CHs
    
    for i = 1:net.N
        if strcmp(net.nodes(i).role, 'MEMBER') && net.nodes(i).E > 0
            ch_idx = net.nodes(i).cluster_head_id;
            
            % Store current state of member and assigned CH
            tx = net.nodes(i);
            rx = net.nodes(ch_idx);
            
            % Transmit packet from member to CH
            [tx_updated, rx_updated, ~] = net.send_packet(tx, rx, net.k_data);
            
            % Update new Energy for node and CH to receive
            net.nodes(i).E = tx_updated.E;
            net.nodes(ch_idx).E = rx_updated.E;
        end
    end
    
    % CHs agg and send to BS
    for ch_idx = net.ch_indices
        if net.nodes(ch_idx).E > 0
            % Count connected cluster members
            cluster_members = sum([net.nodes.cluster_head_id] == ch_idx & strcmp({net.nodes.role}, 'MEMBER'));
            
            % Compression cost
            E_agg = (cluster_members + 1) * net.k_data * net.E_DA;
            net.nodes(ch_idx).E = max(0, net.nodes(ch_idx).E - E_agg);
            
            % Transmit to BS
            [tx_updated, ~, ~] = net.send_packet(net.nodes(ch_idx), net.BS, net.k_data);
            net.nodes(ch_idx).E = tx_updated.E;
        end
    end
    history{r} = copy(net);
end

net.visualize_WSN_history(history)

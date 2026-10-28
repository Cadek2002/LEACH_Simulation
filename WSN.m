classdef WSN < matlab.mixin.Copyable
    properties
        %% WSN Network Setup
        N = 100;                 % Total nodes
        width = 400;             % Field width (meters)
        height = 400;            % Field height (meters)
        E_init = 0.5;          % Initial energy (Joules)
        k_data = 5000;        % Data packet size (bits)
        E_DA = 5e-9;             % Data Aggregation Energy (5 nJ/bit/signal)
        P = .05;                 % Desired portion of CHs
        Round = 1;               % Current Round
        Sensor_Range = hypot(400, 400); % Sensor range, default to max
        ch_indices;
        nodes;
        BS struct = struct();
        initial_energy double = 0.5;
    end

    methods
        function generate_wsn_topology(self)
        % Basic generation (Centered BS, random dist of sensors in a rectangle)
        
        % Default initial energy if not in the WSN struct
        if nargin < 4
            self.initial_energy = 0.5;
        end
        
        % throw BS in the center
        self.BS.x = self.width / 2;
        self.BS.y = self.height / 2;
        
        % node structs
        self.nodes = struct(...
            'id', cell(1, self.N), ...
            'x', cell(1, self.N), ...
            'y', cell(1, self.N), ...
            'E', cell(1, self.N), ...
            'type', cell(1, self.N), ... % 'N' = Normal, 'C' = Cluster Head
            'last_CH_round', cell(1, self.N) ...
            );
        
        % give them all random positions
        %todo OOO make the generator function an input?
        x_coords = rand(1, self.N) * self.width;
        y_coords = rand(1, self.N) * self.height;
        
        %Populate the nodes
        for i = 1:self.N
            self.nodes(i).id = i;
            self.nodes(i).x = x_coords(i);
            self.nodes(i).y = y_coords(i);
            self.nodes(i).E = self.initial_energy;
            self.nodes(i).type = 'N'; % placeholder for now, not doing anything with it
            self.nodes(i).last_CH_round = -1;
            self.nodes(i).role = 'NA';
        end
        end
        
        function [tx_node, rx_node, is_tx_dead] = send_packet(self, tx_node, rx_node, k_bits)
        % gives energy cost for sending packets from node-to-node
        % using the First Order Radio Model (LEACH standard parameters).
        %
        % Inputs:
        %   tx_node - Struct of the transmitting node
        %   rx_node - Struct of the receiving node (or Base Station struct)
        %   k_bits  - Size of the packet in bits (e.g., 4000 bits = 500 bytes)
        %
        % Outputs:
        %   tx_node    - Updated transmitter struct with depleted energy
        %   rx_node    - Updated receiver struct with depleted energy
        %   is_tx_dead - Boolean flag (true if tx_node depleted all energy)
        
        % Standard First Order Radio Model Hardware Constants
        E_elec = 50e-9;      % 50 nJ/bit (Transmitter/Receiver Electronics Energy)
        E_fs   = 10e-12;     % 10 pJ/bit/m^2 (Free Space Amplifier Model)
        E_mp   = 0.0013e-12; % 0.0013 pJ/bit/m^4 (Multipath Amplifier Model)
        
        % Threshold distance to decide what interference model we have to use (d0)
        
        
        
        % is also when these models intersect for distance, threshold for swapping
        % to free space model
        d0 = sqrt(E_fs / E_mp);
        
        % calculate dist btw sender and receiver
        dx = tx_node.x - rx_node.x;
        dy = tx_node.y - rx_node.y;
        dist = sqrt(dx^2 + dy^2);
        
        % calculate Tx Energy cost based on distance, and what interference model
        % to use
        if dist < d0
            E_tx = (k_bits * E_elec) + (k_bits * E_fs * (dist^2));
        else
            E_tx = (k_bits * E_elec) + (k_bits * E_mp * (dist^4));
        end
        
        % calculate Rx Energy cost (receiver) Literally cost to process the info
        E_rx = k_bits * E_elec;
        
        % drain energy from Transmitter
        tx_node.E = tx_node.E - E_tx;
        
        % check if transmitter died during this transmission
        if tx_node.E <= 0
            tx_node.E = 0;
            is_tx_dead = true;
        else
            is_tx_dead = false;
        end
        
        % drain energy from Receiver (if it's a regular sensor node, not BS)
        if isfield(rx_node, 'E')
            rx_node.E = rx_node.E - E_rx;
            if rx_node.E < 0
                rx_node.E = 0;
            end
        end
        end
        
        function visualize_WSN(self, ax)
            

if nargin < 2
    fig = figure('Name', 'WSN Energy State After LEACH Round', 'NumberTitle', 'off');
    ax = gca;
else
    fig = ancestor(ax, 'figure');
end

% Draw w/ targeted a
% 
% xis
hold(ax, 'on'); 
grid(ax, 'on');

% Get data from node list for plotting/tooltips
x_coords = [self.nodes.x];
y_coords = [self.nodes.y];
energies = [self.nodes.E];
node_ids = [self.nodes.id];
node_roles = {self.nodes.role};

% Draw lines from nodes to CHs
h_line = gobjects(0);
for i = 1:self.N
    if strcmp(self.nodes(i).role, 'MEMBER') && self.nodes(i).cluster_head_id > 0
        ch_idx = self.nodes(i).cluster_head_id;
        h_line = line(ax, [self.nodes(i).x, self.nodes(ch_idx).x], ...
            [self.nodes(i).y, self.nodes(ch_idx).y], ...
            'Color', [0.7 0.7 0.7], 'LineStyle', '--');
    end
end

% Draw CH markers, black for now cause theyre annoying and its pretty
% obvious who the CHs are
h_ch = gobjects(0);
for ch_idx = self.ch_indices
    h_ch = plot(ax, self.nodes(ch_idx).x, self.nodes(ch_idx).y, 'ks', ...
        'MarkerSize', 12, 'LineWidth', 2);
end

% Plot Node points, use remaining energy for color
h_node = scatter(ax, x_coords, y_coords, 60, ...
                 'CData', energies, ...
                 'MarkerFaceColor', 'flat', ...
                 'MarkerEdgeColor', 'k');

% Color map on target (using jet scaling)
colormap(ax, jet);

% Draw Color bar legend
c = colorbar(ax);
c.Label.String = 'Remaining Energy (Joules)';

% Limit colorbar scal from the starting energy to zero
E_max = self.E_init;
if max(energies) > E_max
    E_max = max(energies); % Just in case for some reason a node gains energy (Add solar powered nodes?)
end

clim(ax, [0, E_max]); % Modern MATLAB syntax (R2022a+)

% Tooltip config
row = dataTipTextRow('Node ID', node_ids, '%d');
h_node.DataTipTemplate.DataTipRows(1) = row; 
h_node.DataTipTemplate.DataTipRows(2).Label = 'X Pos';
h_node.DataTipTemplate.DataTipRows(2).Format = '%.2f m';
rowY = dataTipTextRow('Y Pos', y_coords, '%.2f m');
h_node.DataTipTemplate.DataTipRows(3) = rowY;
rowE = dataTipTextRow('Energy', energies, '%.4f J');
h_node.DataTipTemplate.DataTipRows(4) = rowE;
rowRole = dataTipTextRow('Role', node_roles);
h_node.DataTipTemplate.DataTipRows(5) = rowRole;

datacursormode(fig, 'on');

% Base Station is a triangle
h_bs = plot(ax, self.BS.x, self.BS.y, 'r^', 'MarkerFaceColor', 'r', 'MarkerSize', 14);

% Labels
title(ax, sprintf('WSN Node Energy Distribution & Cluster Topology (Round %d)', self.Round));
xlabel(ax, 'X Position (m)');
ylabel(ax, 'Y Position (m)');
xlim(ax, [0, self.width]);
ylim(ax, [0, self.height]);

% Legend handles
legend(ax, [h_node, h_ch, h_bs, h_line], ...
    {'Sensor Node', 'Cluster Head (CH)', 'Base Station (BS)', 'Cluster Connection'}, ...
    'Location', 'northeastoutside');
end
    
        function visualize_WSN_history(self, history)
    num_rounds = length(history);
    % WINDOW
    fig = figure('Name', 'WSN LEACH Simulation Viewer', ...
        'NumberTitle', 'off', ...
        'Position', [100, 100, 900, 650]);

    % cluster axis
    ax = axes('Parent', fig, 'Position', [0.10, 0.20, 0.70, 0.72]);

    % UI Slider for selecting rounds
    slider = uicontrol('Parent', fig, 'Style', 'slider', ...
        'Min', 1, 'Max', num_rounds, 'Value', 1, ...
        'SliderStep', [1/(num_rounds-1), 1/(num_rounds-1)], ...
        'Position', [180, 30, 450, 20], ...
        'Callback', @updatePlot);

    % Print what round were on at the top
    lbl = uicontrol('Parent', fig, 'Style', 'text', ...
        'Position', [330, 55, 150, 20], ...
        'String', sprintf('Round: 1 / %d', num_rounds), ...
        'FontSize', 10, 'FontWeight', 'bold');

    % Default to 1
    plotFrame(1);

    % Update the graph with the select round when the slider is moved
    function updatePlot(src, ~)
        current_round = round(src.Value);
        src.Value = current_round; % Snap to integer step
        lbl.String = sprintf('Round: %d / %d', current_round, num_rounds);
        plotFrame(current_round);
    end

    % Render
    function plotFrame(r)
        cla(ax); % Clear previous contents
        WSN = history{r};

        % Build the graph with the correct round
        visualize_WSN(WSN, ax); 
    end
end

    % Original LEECH assignment, 1/P-round Cycles where everyone is a CH in
    % that time
    function LEACH_Clustering(self)
        self.ch_indices = [];
    
        % Default all nodes to MEMBER
        for i = 1:self.N
            self.nodes(i).role = 'MEMBER';
            self.nodes(i).cluster_head_id = 0;
        end
    
        cycle_length = 1 / self.P;
        current_cycle_round = mod(self.Round - 1, cycle_length);
    
        % Calculate cycle start round for current cycle (1, 21, 41, etc.)
        cycle_start_round = (floor((self.Round - 1) / cycle_length) * cycle_length) + 1;
    
        % Probability threshold for current round in cycle
        T_n = self.P / (1 - self.P * current_cycle_round);
        assignment_thresholds = rand(1, self.N);
    
        for i = 1:self.N
            % Skip dead nodes
            if self.nodes(i).E <= 0
                continue;
            end
    
            % Node is eligible if it hasn't served as CH in the CURRENT cycle
            is_eligible = (self.nodes(i).last_CH_round < cycle_start_round);
    
            if is_eligible
                if assignment_thresholds(i) < T_n
                    self.nodes(i).role = 'CH';
                    self.nodes(i).last_CH_round = self.Round;
                    self.nodes(i).cluster_head_id = -1;
                    self.ch_indices(end + 1) = i;
                end
            end
        end
    end
    
    % Literally just randomly assigns the required percentage of CHs every
    % round
    function random_Clustering(self)
        num_CHs = round(0.05 * self.N);
        self.ch_indices = randperm(self.N, num_CHs); 
        % Default all ndoes to Member
        for i = 1:self.N
            self.nodes(i).role = 'MEMBER';
            self.nodes(i).cluster_head_id = 0;
        end
        % Give CHs their role
        for i = self.ch_indices
            self.nodes(i).role = 'CH';
            self.nodes(i).cluster_head_id = -1;
        end
    end



    end

    methods (Access = protected)
        function cpObj = copyElement(obj)
            cpObj = copyElement@matlab.mixin.Copyable(obj);
        end
    end
end
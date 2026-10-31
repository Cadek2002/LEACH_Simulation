import IDE.*
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

% Initialize candidate virtual-node placements within the network bounds

ide = IDE();

ide.run(net, 100, 10)

disp(ide.top_member)
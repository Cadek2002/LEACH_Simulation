import IDE.*
import WSN.*
%womp womp
clear; clc; close all;

params.alpha = .3;
params.beta = .3;
params.gamma = .4;
mu = .5;
a = .5;
b = .2;
c = .3;
params.m = 25;

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
[net.nodes, net.BS] = WSN.generate_wsn_topology(net);

% Initialize candidate virtual-node placements within the network bounds
ide = IDE();

numVirtualNodes = 10;
lowerBounds = repmat([0, 0], 1, numVirtualNodes);
upperBounds = repmat([net.width, net.height], 1, numVirtualNodes);
 
ide.initialize_population(50, 2 * numVirtualNodes, lowerBounds, upperBounds, 3);


fitness = ide.evaluate(net, ide.P, @(row, context) ide.CRPIDE_fitness(row, context));

disp(ide.P)
disp(fitness)
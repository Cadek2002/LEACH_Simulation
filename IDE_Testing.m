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
ide.context = net;


numVirtualNodes = 10;
ide.x_L = repmat([0, 0], 1, numVirtualNodes);
ide.x_U = repmat([net.width, net.height], 1, numVirtualNodes);

ide.initialize_population(50, 2 * numVirtualNodes, 3);

for i = 1:100
    ide.run_iteration();
end

fitness = ide.evaluate(ide.P, @(row) ide.CRPIDE_fitness(row));
varNames = [compose("x%d", 1:size(ide.P, 2)), "fitness"];

% Round both population and fitness to 2 decimal places numerically
P_rounded = round(ide.P, 2);
fit_rounded = round(fitness(:), 2);

T = array2table([P_rounded, fit_rounded], 'VariableNames', cellstr(varNames));
disp(T)
% Test residualEnergyFactor

E_init = 0.5;
mu = 0.5;

% Two sensor nodes
nodes(1).x = 0;
nodes(1).y = 0;

nodes(2).x = 10;
nodes(2).y = 0;

% One virtual cluster head
VCH_positions = [1, 0];

%% Test 1: All nodes have full energy
nodes(1).E = 0.5;
nodes(2).E = 0.5;

penalty1 = residualEnergyFactor(VCH_positions, nodes, E_init, mu);

fprintf('Test 1 - Full energy: %.4f\n', penalty1);

%% Test 2: One node has depleted energy
nodes(1).E = 0.25;
nodes(2).E = 0.5;

penalty2 = residualEnergyFactor(VCH_positions, nodes, E_init, mu);

fprintf('Test 2 - Depleted energy: %.4f\n', penalty2);

%% Test 3: All nodes are dead
nodes(1).E = 0;
nodes(2).E = 0;

penalty3 = residualEnergyFactor(VCH_positions, nodes, E_init, mu);

fprintf('Test 3 - All nodes dead: %.4f\n', penalty3);
% Test multiHopCandidacy independently

BS.x = 0;
BS.y = 0;

% Test 1: Good relay straight path balanced distances
VCH_positions = [8, 0; 4, 0];
penalty1 = multiHopCandidacy(VCH_positions, BS);

% Test 2: Poor relay angle exceeds cutoff
VCH_positions = [0, 8; 4, 4];
penalty2 = multiHopCandidacy(VCH_positions, BS);

% Test 3: Unbalanced hop distances
VCH_positions = [9, 0; 1, 0];
penalty3 = multiHopCandidacy(VCH_positions, BS);

% Test 4: one VCH
VCH_positions = [5, 0];
penalty4 = multiHopCandidacy(VCH_positions, BS);

fprintf('Test 1 - Good relay: %.4f\n', penalty1);
fprintf('Test 2 - Poor angle: %.4f\n', penalty2);
fprintf('Test 3 - Unbalanced hops: %.4f\n', penalty3);
fprintf('Test 4 - One VCH: %.4f\n', penalty4);

% Test 5: VCH with no closer relay, but not closest to BS
VCH_positions = [5, 0; 10, 0; 20, 0];
penalty5 = multiHopCandidacy(VCH_positions, BS);

fprintf('Test 5 - No closer relay: %.4f\n', penalty5);

% Test 6: Two VCHs equally far from the BS
VCH_positions = [10, 0; -10, 0];
penalty6 = multiHopCandidacy(VCH_positions, BS);

fprintf('Test 6 - Equal distance: %.4f\n', penalty6);
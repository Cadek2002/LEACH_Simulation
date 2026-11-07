
function penalty = multiHopCandidacy(VCH_positions, BS, cutoffAngle)

    if nargin < 3
        cutoffAngle = pi/4;
    end

    numVCH = size(VCH_positions, 1);

    if numVCH < 2
        penalty = 1;
        return;
    end

    % Base station coordinates
    bsPosition = [BS.x, BS.y];

    % Calculate the distance from each VCH to the base station
    bsDistances = zeros(numVCH, 1);

    for i = 1:numVCH
        dx = VCH_positions(i, 1) - bsPosition(1);
        dy = VCH_positions(i, 2) - bsPosition(2);

        bsDistances(i) = sqrt(dx^2 + dy^2);
    end

    % Identify VCHs that could act as relay nodes
    relayCandidates = cell(numVCH, 1);

    for i = 1:numVCH
        for j = 1:numVCH

            % A relay different VCH closer to the BS
            if i ~= j && bsDistances(j) < bsDistances(i)
                relayCandidates{i} = [relayCandidates{i}; j];
            end

        end
    end

    % Calculate the angle between each VCH and potential relay
    angleScores = cell(numVCH, 1);
    % Store the distance suitability penalties for each relay
    distanceScores = cell(numVCH, 1);

    for i = 1:numVCH
        candidates = relayCandidates{i};
        angleScores{i} = zeros(length(candidates), 1);
        distanceScores{i} = zeros(length(candidates), 1);

        for k = 1:length(candidates)
            j = candidates(k);

            % Vector from current VCH to relay
            v1 = VCH_positions(j, :) - VCH_positions(i, :);

            % Vector from relay to base station
            v2 = bsPosition - VCH_positions(j, :);

            % Calculate angle between two vectors
            denominator = norm(v1) * norm(v2);

            if denominator > 0
                cosTheta = dot(v1, v2) / denominator;
                cosTheta = max(-1, min(1, cosTheta));
                angleScores{i}(k) = acos(cosTheta);
            end
            % Compare two hop distances
            distanceToRelay = norm(v1);
            distanceRelayToBS = norm(v2);

            if distanceToRelay > 0 && distanceRelayToBS > 0
                ratio = distanceToRelay / distanceRelayToBS;

                % A ratio close to 1 means two hops are balanced
                distanceScores{i}(k) = 1 - exp(-abs(log(ratio)));
            else
                distanceScores{i}(k) = 1;
            end
        end
    end
    % Calculate the multihop candidacy penalty
    totalPenalty = 0;

    for i = 1:numVCH
        candidates = relayCandidates{i};

        % Only exempt the uniquely closest VCH to the BS.
        [minDistance, ~] = min(bsDistances);
        closestVCHs = find(abs(bsDistances - minDistance) < 1e-9);

        if numel(closestVCHs) == 1 && i == closestVCHs(1)
            continue;
        end

        % Penalize VCHs that have no closer relay.
        if isempty(candidates)
            totalPenalty = totalPenalty + 1;
            continue;
        end

        % Find relays that satisfy angle requirement
        validAngles = angleScores{i} <= cutoffAngle;
        if any(validAngles)
            % Calculate a combined angle and distance penalty.
            combinedScores = 0.5 * (angleScores{i}(validAngles) / cutoffAngle) ...
                        + 0.5 * distanceScores{i}(validAngles);

            % Choose relay with lowest combined penalty
            bestScore = min(combinedScores);

            totalPenalty = totalPenalty + bestScore;
        else
            % Penalize VCHs without suitable relay
            totalPenalty = totalPenalty + 1;
        end
    end

    % Normalize penalty between 0 and 1
    penalty = totalPenalty / numVCH;

end

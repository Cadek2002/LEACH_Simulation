classdef IDE < handle
    
    properties
        alpha double {mustBePositive} = .3;
        beta double {mustBePositive} = .3;
        gamma double {mustBePositive} = .4;
        mu double {mustBePositive} = .5;
        a double {mustBePositive} = .5;
        b double {mustBePositive} = .2;
        c double {mustBePositive} = .3;
        m {mustBePositive} = 25;
        context struct;
        mutation_rate double {mustBePositive} = .9;
        crossover_rate = .9;
        exponential_crossover_prob = .6;
        P;
        neighboorhood_size {mustBePositive} = 10;
        x_L;
        x_U;
        D;
    end

    
    
    
    
    
    
    methods
        function initialize_population(self, N, D, Q)
            % Define J using the pop and Q (any odd number)
            J = 1;
            self.D = D;
            
            if nargin < 5
                Q = 3; % default Q, doesn't really matter
            end
        
        
            % log(N*(Q-1)+1)/log(Q); %funciton from paper
        
            while true
                M = Q^J;
                N_calc = (Q^J-1) / (Q-1);
                if M >= N && N_calc >= D
                    break
                end
                J = J+1;
        
                if J > 12
                    disp("Q val too lareg");
                end
            end
            
            % init array
            digits = zeros(M, J);
            for i = 0:M-1
                val = i;
                for k = 1:J
                    digits(i+1, k) = mod(val, Q);
                    val = floor(val / Q);
                end
            end
        
            all_v = dec2base(0:Q^J-1, Q) - '0';
            valid_cols = [];
            for i = 1:size(all_v, 1)
                v = all_v(i, :);
                nz_idx = find(v> 0, 1);
                %cols where the first non-zero coefficient is 1
                if ~isempty(nz_idx) && v(nz_idx) == 1
                    valid_cols = [valid_cols; v];
                end
            end
        
            N_cols = size(valid_cols, 1);
            A = zeros(M, N_cols);
            for j = 1:N_cols
                v = valid_cols(j, :);
                A(:, j) = mod(digits * v', Q) + 1;
            end
        
            %select random rows
            rand_rows = randperm(M, N);
            %trim
            A_trimmed = A(rand_rows, :);
        
            %Map vals to decision variable domain
            min_A = min(A_trimmed(:));
            max_A = max(A_trimmed(:));
            if max_A == min_A
                max_A = min_A + 1; % Prevent division by zero if degenerate
            end
        
            %if bounds are scalar, assume all the same ofc
             if isscalar(self.x_L), self.x_L = self.x_L * ones(1, D); end
             if isscalar(self.x_U), self.x_U = self.x_U * ones(1, D); end
        
            %normalize pop
            self.P = zeros(N, D);
            for j = 1:D
                normalized = (A_trimmed(:, j) - min_A) / (max_A - min_A);
                self.P(:, j) = normalized * (self.x_U(j) - self.x_L(j)) + self.x_L(j);
            end
        end

        function fitness = evaluate(self, population, fitnessFunction)
            fitness = arrayfun(@(row) fitnessFunction(population(row, :)), ...
                               1:size(population, 1));
        end
        
        function score = CRPIDE_fitness(self, row)
            VCH = 0;
       
            %define vector of 0s of length equal to the number of nodes
            
            covered = zeros(1, self.context.N);
        
            x_edges = linspace(0, self.context.width, self.m + 1);
            y_edges = linspace(0, self.context.height, self.m + 1);
        
            gridCovered = false(self.m, self.m);

            for k = 1:length(row)/2
                virtual_x = row(2*k-1);
                virtual_y = row(2*k);
                VCH = VCH + hypot(virtual_x - self.context.BS.x, virtual_y - self.context.BS.y);
        
                
                [x0, y0] = ndgrid(x_edges(1:end-1), y_edges(1:end-1));
                [x1, y1] = ndgrid(x_edges(2:end), y_edges(2:end));
        
                % if the four corners of the grid are in range than the grid space
                % is fully encompassed
                enclosed = hypot(x0 - virtual_x, y0 - virtual_y) <= self.context.Sensor_Range & ...
                           hypot(x0 - virtual_x, y1 - virtual_y) <= self.context.Sensor_Range & ...
                           hypot(x1 - virtual_x, y0 - virtual_y) <= self.context.Sensor_Range & ...
                           hypot(x1 - virtual_x, y1 - virtual_y) <= self.context.Sensor_Range;
       
        
                gridCovered = gridCovered | enclosed;

                for j = 1:length(self.context.nodes)
                    node = self.context.nodes(j);
                    dist = hypot(node.x - virtual_x, node.y - virtual_y);
        
                    if dist <= self.context.Sensor_Range
                        VCH = VCH + hypot(node.x - virtual_x, node.y - virtual_y);
                        covered(j) = 1;
                    end
                end 
            end     
        
            denom = 0;
        
            for j = 1:length(self.context.nodes)
                node = self.context.nodes(j);
                denom = denom + hypot(node.x - self.context.BS.x, node.y - self.context.BS.y);
            end 
        
            VCH = VCH / denom;
            grid_score = nnz(gridCovered);

            %full CRPIDE fitness function
            score = self.alpha * VCH + self.beta * (sum(covered) / self.context.N) + self.gamma * (grid_score / (self.m + 1)^2); 
        
        end
    
        function debug = run_iteration(self)
            population = self.P;
            fitness = self.evaluate(population, @self.CRPIDE_fitness);
            [bestFitness, bestIndex] = min(fitness);
            self.P = population(bestIndex, :);

            %Grab top 25% of performers from the current population
            [~, rankedIndices] = sort(fitness, 'ascend');
            eliteCount = max(1, ceil(0.25 * size(population, 1)));
            elitePopulation = population(rankedIndices(1:eliteCount), :);
            
            % generate mutated population by taking each member of the
            % population, and adding a random member of the elite
            % population, minus the original member plus the difference
            % between two distinct members of the population

            populationSize = size(population, 1);
            mutatedPopulation = zeros(size(population));
            for i = 1:populationSize
                elite = elitePopulation(randi(eliteCount), :);
                indices = randperm(populationSize, 2);
                mutatedPopulation(i, :) = population(i, :) + self.mutation_rate * (elite - population(i, :) + ...
                    population(indices(1), :) - population(indices(2), :));
            end

            %Generate trial population using unitary / exponential

            trialPopulation = population;
            for i = 1:populationSize
                if rand < self.exponential_crossover_prob %exponential
                    startIndex = randi(size(population, 2));
                    crossoverLength = randi(size(population, 2));
                    indices = mod(startIndex - 1 + (0:crossoverLength-1), size(population, 2)) + 1;
                    trialPopulation(i, indices) = mutatedPopulation(i, indices);
                else %unitary
                    mask = rand(1, size(population, 2)) < self.crossover_rate;
                    mask(randi(size(population, 2))) = true;
                    trialPopulation(i, mask) = mutatedPopulation(i, mask);
                end
            end
            %clamp to playfield
            for d = 1:self.D
                trialPopulation(:, d) = max(min(trialPopulation(:, d), self.x_U(d)), self.x_L(d));
            end

            % run fitness on trial population
            trialFitness = self.evaluate(trialPopulation, @self.CRPIDE_fitness);


            %Conservitive selection: only let a trial member in if it beats
            %its counterpart AND a quarter of randomly selected members of
            %both pops
            currentFitness = fitness;
            replaceMask = false(populationSize, 1);
            
            neighborCount = min(self.neighboorhood_size, populationSize - 1); %neighborhood size bounds
            requiredBeats = max(1, ceil(0.25 * neighborCount)); %neighboors needed to be beaten
            
            for i = 1:populationSize
                pool = setdiff(1:populationSize, i);
                neighborIndices = pool(randperm(numel(pool), neighborCount));
            
                beatsCurrent = trialFitness(i) < currentFitness(i);
                beatsNeighbors = nnz(trialFitness(i) < max(currentFitness(neighborIndices), trialFitness(neighborIndices))) >= requiredBeats;
            
                replaceMask(i) = beatsCurrent && beatsNeighbors;
            end
            
            population(replaceMask, :) = trialPopulation(replaceMask, :);

            self.P = population;
            debug = replaceMask;
            
        end
    end
end



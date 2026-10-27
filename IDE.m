classdef IDE < handle
    
    properties
        alpha double {mustBePositive} = .3;
        beta double {mustBePositive} = .3;
        gamma double {mustBePositive} = .4;
        mu double {mustBePositive} = .5;
        a double {mustBePositive} = .5;
        b double {mustBePositive} = .2;
        c double {mustBePositive} = .3;
        m int16 {mustBePositive} = 25;
        context struct;
        P;
    end

    methods
        function initialize_population(self, N, D, x_L, x_U, Q)
            % Define J using the pop and Q (any odd number)
            J = 1;
            
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
             if isscalar(x_L), x_L = x_L * ones(1, D); end
             if isscalar(x_U), x_U = x_U * ones(1, D); end
        
            %normalize pop
            self.P = zeros(N, D);
            for j = 1:D
                normalized = (A_trimmed(:, j) - min_A) / (max_A - min_A);
                self.P(:, j) = normalized * (x_U(j) - x_L(j)) + x_L(j);
            end
        end
        
        

        function fitness = evaluate(self, context, population, fitnessFunction)
            fitness = arrayfun(@(row) fitnessFunction(population(row, :), context), ...
                               1:size(population, 1));
        end
        
        function score = CRPIDE_fitness(self, row, context)
            VCH = 0;
        
            grid_score = 0;
            %define vector of 0s of length equal to the number of nodes
            
            covered = zeros(1, numel(context.N));
        
            x_edges = linspace(0, context.width, self.m + 1);
            y_edges = linspace(0, context.height, self.m + 1);
        
            gridCovered = false(self.m, self.m);
            grid_score = 0;

            for k = 1:length(row)/2
                virtual_x = row(2*k-1);
                virtual_y = row(2*k);
                VCH = VCH + hypot(virtual_x - context.BS.x, virtual_y - context.BS.y);
        
                
                [x0, y0] = ndgrid(x_edges(1:end-1), y_edges(1:end-1));
                [x1, y1] = ndgrid(x_edges(2:end), y_edges(2:end));
        
                % if the four corners of the grid are in range than the grid space
                % is fully encompassed
                enclosed = hypot(x0 - virtual_x, y0 - virtual_y) <= context.Sensor_Range & ...
                           hypot(x0 - virtual_x, y1 - virtual_y) <= context.Sensor_Range & ...
                           hypot(x1 - virtual_x, y0 - virtual_y) <= context.Sensor_Range & ...
                           hypot(x1 - virtual_x, y1 - virtual_y) <= context.Sensor_Range;
       
        
                newlyCovered = enclosed & ~gridCovered;
                gridCovered = gridCovered | enclosed;
                grid_score = grid_score + nnz(newlyCovered);

                for j = 1:length(context.nodes)
                    node = context.nodes(j);
                    dist = hypot(node.x - virtual_x, node.y - virtual_y);
        
                    if dist <= context.Sensor_Range
                        VCH = VCH + hypot(node.x - virtual_x, node.y - virtual_y);
                        covered(j) = 1;
                    end
                end 
            end     
        
            denom = 0;
        
            for j = 1:length(context.nodes)
                node = context.nodes(j);
                denom = denom + hypot(node.x - context.BS.x, node.y - context.BS.y);
            end 
        
            VCH = VCH / denom;
            grid_score = nnz(gridCovered);

            %full CRPIDE fitness function
            score = self.alpha * VCH + self.beta * (sum(covered) / context.N) + self.gamma * (grid_score / (self.m + 1)^2); 
        
        end
    
    end
end



%% basic chunking simulation

% meta simulation parameters
%log_version = 1;

function [mse_log, weight_corr_pairs, corr_trajectory] = chunking_sim(num_objects, num_main_positions, num_extra_positions)

% set up network parameters
nHidden = 250;              % number of hidden units
learningRate = 0.1;         % learning rate
thresh = 0.0001;             % mean-squared error stopping criterion for training
decay = 0.0000;             % weight penalization parameter
bias = -2;                  % weight from bias units to hidden & output units (bias is added to net input of every hidden and output unit)
init_scale = 0.1;           % scales for initialized random weights, i.e. the initial weights range from [-init_scale, +init_scale]
iterations_train = 2000;     % number of training iterations
num_training_patterns = 150; % number of training patterns

% create training environment for remembering only one object-location pair in working
% memory

NObjects = num_objects;           % total number of different objects to remember: A, B, C, D, E, F
NPositions = num_main_positions;  % total number of positions that objects can be placed on the screen: 1, 2, 3, 4, 5, 6
NLoadPositions = num_extra_positions; % total number of positions for objects added only to increase memory load

NWorkingMemoryItems = NObjects * (NPositions + NLoadPositions);  % the number of different object-position associations

% initialize the RNG for data creation
rng('shuffle', 'twister');

% start training networks
while true
    mse_log = zeros(1, iterations_train); % custom MSE log
    corr_trajectory = zeros(2, iterations_train); % trajectory of TH correlations throughout training
    for iter = 1:iterations_train
        training_task_data = zeros(num_training_patterns, NWorkingMemoryItems);
        training_object_patterns = zeros(num_training_patterns, NObjects);
        training_position_patterns = zeros(num_training_patterns, NPositions + NLoadPositions);
        
        % pick training set
        for i = 1:num_training_patterns
            object_indices = 1:NPositions;
            % A should be in positions 1 - NPositions
            A_index = round(rand * (NPositions - 1)) + 1;
            if rand < 0.8 % enforce the correlation
                B_index = mod(A_index + 1, NPositions);
                if B_index == 0
                    B_index = NPositions;
                end
            else
                B_index = mod(A_index - 1, NPositions);
                if B_index == 0
                    B_index = NPositions;
                end
            end
            
            distractor_indices = object_indices;
            distractor_indices([find(object_indices == A_index), find(object_indices == B_index)]) = [];
            distractor_indices = distractor_indices(randperm(length(distractor_indices))); % randomly permute the distractors
            
            object_indices = [A_index, B_index, distractor_indices];
            
            % pick locations for memory load objects
            load_object_indices = (NPositions + 1):(NPositions + NLoadPositions);
            load_object_indices = load_object_indices(randperm(length(load_object_indices)));
            for j = 1:length(load_object_indices)
                if rand < 0.5
                    load_object_indices(j) = 0;
                end
            end
            
            object_indices = [object_indices, load_object_indices];
            
            % convert object indices to task layer representation
            for j = 1:length(object_indices)
                if object_indices(j) == 0
                    continue
                end
                
                index = ((j - 1) * (NPositions + NLoadPositions)) + object_indices(j);
                training_task_data(i, index) = 1;   
            end
            
            % pick an object to cue
            object_set = 1:NObjects;
            object_set(find(object_indices == 0)) = [];
            object_set(3:(NObjects - NLoadPositions)) = [];
            
            training_object_patterns(i, object_set(round(rand * (length(object_set) - 1)) + 1)) = 1;
            
            % activate the appropriate output node
            training_position_patterns(i, object_indices(find(training_object_patterns(i, :)))) = 1;
        end
        
        %create and train network
        if iter == 1
            chunkingNet = NNmodel(nHidden, learningRate, bias, init_scale, thresh, decay);
            chunkingNet.setData(training_object_patterns, training_task_data, training_position_patterns);
            chunkingNet.configure()
            displayIterations = 0;
            chunkingNet.trainOnline(1,[],[],[],displayIterations);
        else
            chunkingNet.setData(training_object_patterns, training_task_data, training_position_patterns);
            chunkingNet.trainOnline(1,[],[],[],displayIterations);
        end
        
        % get net data
        
        % update mse log for trial
        mse_log(iter) = chunkingNet.MSE_log(end);
        
        % get correlation trajectory
        th_corr = corr(chunkingNet.weights.W_TH);
        for j = 1:NPositions
            pattern_index = mod(j + 1, NPositions);
            antipattern_index = mod(j - 1, NPositions);
            if pattern_index == 0
                pattern_index = NPositions;
            end
            
            if antipattern_index == 0
                antipattern_index = NPositions;
            end

            corr_trajectory(1, iter) = corr_trajectory(1, iter) + th_corr(j, NPositions + pattern_index); % pattern
            corr_trajectory(2, iter) = corr_trajectory(2, iter) + th_corr(j, NPositions + antipattern_index); % antipattern
        end
        
        corr_trajectory(1, iter) = corr_trajectory(1, iter) / NPositions;
        corr_trajectory(2, iter) = corr_trajectory(2, iter) / NPositions;
        
        % do some cleanup, and then exit
        if (chunkingNet.MSE_log(end) <= thresh)
            corr_trajectory(1, iter:end) = corr_trajectory(1, iter);
            corr_trajectory(2, iter:end) = corr_trajectory(2, iter);
            
            break;
        end
    end
        
    if (chunkingNet.MSE_log(end) <= thresh)
        break;
    end
end

% get weight correlations for the task-hidden layer
weight_corr_pairs = corr(chunkingNet.weights.W_TH);

end
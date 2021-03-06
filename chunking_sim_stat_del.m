%% basic chunking simulation

% meta simulation parameters
%log_version = 1;

function [testMSE_del2, testMSE_del1, testMSE_del0, avg_mse, weight_corr_pairs, corr_trajectory, mse_log, training_error_logs, pattern_logs, chunk_effect] = chunking_sim_stat_del(num_objects, num_positions, num_del, prop_interleaved)

% set up network parameters
nHidden = 300;              % number of hidden units
learningRate = 0.2;         % learning rate
thresh = 0.0001;             % mean-squared error stopping criterion for training
decay = 0.0000;             % weight penalization parameter
bias = -2;                  % weight from bias units to hidden & output units (bias is added to net input of every hidden and output unit)
init_scale = 0.1;           % scales for initialized random weights, i.e. the initial weights range from [-init_scale, +init_scale]
iterations_train = 4000;     % number of training iterations
num_patterns = 4320;         % size of the input space (6 x 6!)
num_training_patterns = 800; % number of training patterns
num_interleaved_training_patterns = 5; % number of training patterns for interleaved trials

% create training environment for remembering only one object-location pair in working
% memory

NObjects = num_objects;       % total number of different objects to remember: A, B, C, D, E, F
NPositions = num_positions;     % total number of positions that objects can be placed on the screen: 1, 2, 3, 4, 5, 6

NWorkingMemoryItems = NObjects * NPositions;  % the number of different object-position associations
num_diag_patterns = num_patterns / (NPositions - 1); % number of diagonal patterns is N! * (N/N-1)

% initialize the RNG for data creation
rng('shuffle', 'twister');

% we will treat each working memory item as a separate task (i.e., as a
% separate unit in the task layer). We will create a set of task patterns,
% one pattern for each working memory object. 
diag_task_data = zeros(num_diag_patterns, NWorkingMemoryItems); % each row is a training trial, 1 for the presented object-location pair, 0 otherwise
diag_object_patterns = zeros(num_diag_patterns, NObjects); % each row is a training trial, 1 for the cued object, 0 otherwise
diag_position_patterns = zeros(num_diag_patterns, NPositions); % each row is a training trial, 1 for the object location, 0 otherwise

adj_task_data = zeros(num_patterns - num_diag_patterns, NWorkingMemoryItems);
adj_object_patterns = zeros(num_patterns - num_diag_patterns, NObjects);
adj_position_patterns = zeros(num_patterns - num_diag_patterns, NPositions);

% generate data by labelling all the permutations of the set {1, 2, ...,
% NObjects} as being either diagonal or not. Each permutation corresponds
% to a task configuration. 
all_perms = perms(1:NPositions); 
k = 1;
l = 1;
for i = 1:size(all_perms) 
    curr_perm = all_perms(i, :);
    data_row = zeros(1, NWorkingMemoryItems);
    
    % convert permutation to a task layer (e.g. [1 2 3 4 5 6] to [1 0 0...]
    for j = 1:NObjects
       index = ((j - 1) * NObjects) + curr_perm(j);
       data_row(index) = 1;
    end
    
    % diagonal is defined as B equal to the position of A + NPos/2 mod NPos
    if curr_perm(2) == mod(curr_perm(1) + (NPositions / 2), NPositions)
        % each task layer representation can have a different input unit
        for j = 1:NObjects
            diag_task_data(k, :) = data_row;
            diag_object_patterns(k, j) = 1;
            diag_position_patterns(k, curr_perm(j)) = 1;
            k = k + 1;
        end
    
    % dealing with the fact that MATLAB is 1-indexed and mod arithmetic is 0-indexed...
    elseif (mod(curr_perm(1) + (NPositions / 2), NPositions) == 0) && (curr_perm(2) == NPositions)
        for j = 1:NObjects
            diag_task_data(k, :) = data_row;
            diag_object_patterns(k, j) = 1;
            diag_position_patterns(k, curr_perm(j)) = 1;
            k = k + 1;
        end
        
    else 
        for j = 1:NObjects
            adj_task_data(l, :) = data_row;
            adj_object_patterns(l, j) = 1;
            adj_position_patterns(l, curr_perm(j)) = 1;
            l = l + 1;
        end
    end
end

derp = 0;
while true
    mse_log = zeros(1, iterations_train);
    corr_trajectory = zeros(3, iterations_train); % diagonal and adjacent
    a_error_log = zeros(4, iterations_train); % 4 error conditions for 3 object pairs
    c_error_log = zeros(4, iterations_train);
    e_error_log = zeros(4, iterations_train);
    chunk_effect = zeros(iterations_train, NWorkingMemoryItems);
    for i = 1:(num_patterns / NObjects) % number of patterns for a given stimulus = num_patterns / NObjects
        logA{i} = [];
        logC{i} = [];
        logE{i} = [];
    end
    for iter = 1:iterations_train
        % build the training set
        if rand < prop_interleaved
            training_task_data = zeros(num_training_patterns, NWorkingMemoryItems);
            training_object_patterns = zeros(num_training_patterns, NObjects); 
            training_position_patterns = zeros(num_training_patterns, NPositions);
            for i = 1:num_training_patterns
                if rand < 0.8
                    row = ceil(rand * (k - 1));
                    training_task_data(i, :) = diag_task_data(row, :);
                    training_object_patterns(i, :) = diag_object_patterns(row, :);
                    training_position_patterns(i, :) = diag_position_patterns(row, :);

                    % hacky way of randomly deleting two random working memory items:
                    % randomly permute {1, ..., NObjects}, and delete the numbers
                    % corresponding to the first num_del indices. Interpret 1 as A, 2 as B,
                    % etc.
                    delete_index = randperm(NObjects);
                    count = 0;
                    for j = 1:NWorkingMemoryItems
                        if training_task_data(i, j) == 1
                            count = count + 1;
                            if ismember(count, delete_index(1:num_del)) == 1
                                training_task_data(i, j) = 0;
                            end
                        end
                    end
                else
                    row = ceil(rand * (l - 1));
                    delete_index = randperm(NObjects);
                    training_task_data(i, :) = adj_task_data(row, :);
                    training_object_patterns(i, :) = adj_object_patterns(row, :);
                    training_position_patterns(i, :) = adj_position_patterns(row, :);
                    count = 0;
                    for j = 1:NWorkingMemoryItems
                        if training_task_data(i, j) == 1
                            count = count + 1;
                            if ismember(count, delete_index(1:num_del)) == 1
                                training_task_data(i, j) = 0;
                            end
                        end
                    end
                end
            end
        else
            training_task_data = zeros(num_interleaved_training_patterns, NWorkingMemoryItems);
            training_object_patterns = zeros(num_interleaved_training_patterns, NObjects); 
            training_position_patterns = zeros(num_interleaved_training_patterns, NPositions);
            for i = 1:num_interleaved_training_patterns
                % does it make sense to have the correlation here?
                % i think it probably doesn't matter
                if rand < 0.8
                    row = ceil(rand * (k - 1));
                    training_task_data(i, :) = diag_task_data(row, :);
                    training_object_patterns(i, :) = diag_object_patterns(row, :);
                    training_position_patterns(i, :) = diag_position_patterns(row, :);

                    objects_to_erase = 1:NObjects;
                    objects_to_erase = objects_to_erase(objects_to_erase ~= find(training_object_patterns(i, :)));
                    
                    spare_index = round(rand * (length(objects_to_erase) - 1)) + 1;
                    objects_to_erase(spare_index) = [];
                    
                    count = 0;
                    for j = 1:NWorkingMemoryItems
                        if training_task_data(i, j) == 1
                            count = count + 1;
                            if ismember(count, objects_to_erase) == 1
                                training_task_data(i, j) = 0;
                            end
                        end
                    end
                else
                    row = ceil(rand * (l - 1));
                    delete_index = randperm(NObjects);
                    training_task_data(i, :) = adj_task_data(row, :);
                    training_object_patterns(i, :) = adj_object_patterns(row, :);
                    training_position_patterns(i, :) = adj_position_patterns(row, :);
                    
                    objects_to_erase = 1:NObjects;
                    objects_to_erase = objects_to_erase(objects_to_erase ~= find(training_object_patterns(i, :)));
                    
                    spare_index = round(rand * (length(objects_to_erase) - 1)) + 1;                    
                    objects_to_erase(spare_index) = [];
                    
                    count = 0;
                    for j = 1:NWorkingMemoryItems
                        if training_task_data(i, j) == 1
                            count = count + 1;
                            if ismember(count, objects_to_erase) == 1
                                training_task_data(i, j) = 0;
                            end
                        end
                    end
                end  
            end
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
        
        % buckle up.
        
        % MSE testing
        a_mse_object_patterns = [];
        a_mse_position_patterns = [];
        a_mse_task_data = [];
        c_mse_object_patterns = [];
        c_mse_position_patterns = [];
        c_mse_task_data = [];
        %
        e_mse_object_patterns = [];
        e_mse_position_patterns = [];
        e_mse_task_data = [];
        %}
        % going to do this in a dumb way for the sake of just getting it done
        for i = 1:size(diag_object_patterns)
            if diag_object_patterns(i, 1) == 1
                a_mse_object_patterns = [a_mse_object_patterns;diag_object_patterns(i, :)];
                a_mse_task_data = [a_mse_task_data;diag_task_data(i, :)];
                a_mse_position_patterns = [a_mse_position_patterns;diag_position_patterns(i, :)];
            elseif diag_object_patterns(i, 3) == 1
                c_mse_object_patterns = [c_mse_object_patterns;diag_object_patterns(i, :)];
                c_mse_task_data = [c_mse_task_data;diag_task_data(i, :)];
                c_mse_position_patterns = [c_mse_position_patterns;diag_position_patterns(i, :)];
            %
            elseif diag_object_patterns(i, 5) == 1
                e_mse_object_patterns = [e_mse_object_patterns;diag_object_patterns(i, :)];
                e_mse_task_data = [e_mse_task_data;diag_task_data(i, :)];
                e_mse_position_patterns = [e_mse_position_patterns;diag_position_patterns(i, :)];
            %}
            end
        end

        for i = 1:size(adj_object_patterns)
            if adj_object_patterns(i, 1) == 1
                a_mse_object_patterns = [a_mse_object_patterns;adj_object_patterns(i, :)];
                a_mse_task_data = [a_mse_task_data;adj_task_data(i, :)];
                a_mse_position_patterns = [a_mse_position_patterns;adj_position_patterns(i, :)];
            elseif adj_object_patterns(i, 3) == 1
                c_mse_object_patterns = [c_mse_object_patterns;adj_object_patterns(i, :)];
                c_mse_task_data = [c_mse_task_data;adj_task_data(i, :)];
                c_mse_position_patterns = [c_mse_position_patterns;adj_position_patterns(i, :)];
            %
            elseif adj_object_patterns(i, 5) == 1
                e_mse_object_patterns = [e_mse_object_patterns;adj_object_patterns(i, :)];
                e_mse_task_data = [e_mse_task_data;adj_task_data(i, :)];
                e_mse_position_patterns = [e_mse_position_patterns;adj_position_patterns(i, :)];
            %}
            end
        end

        [aData, aHidden, aMSE] = chunkingNet.runSet(a_mse_object_patterns, a_mse_task_data, a_mse_position_patterns);
        [cData, cHidden, cMSE] = chunkingNet.runSet(c_mse_object_patterns, c_mse_task_data, c_mse_position_patterns);
        %
        [eData, eHidden, eMSE] = chunkingNet.runSet(e_mse_object_patterns, e_mse_task_data, e_mse_position_patterns);
        %}
        dcnt = 0;
        acnt = 0;
        for i = 1:size(aData, 1)
            curr_row = aData(i, :);
            true_position = find(a_mse_position_patterns(i, :));
            diagonal_index = mod(true_position + (NPositions / 2), NPositions);
            if diagonal_index == 0
                diagonal_index = NPositions;
            end

            object_indices = find(a_mse_task_data(i, NPositions + 1:end));
            b_index = object_indices(1);

            if b_index == diagonal_index % A and B are diagonal
                dcnt = dcnt + 1;
                a_error_log(1, iter) = a_error_log(1, iter) + curr_row(diagonal_index);
                curr_row([diagonal_index, true_position]) = 0;
                a_error_log(2, iter) = a_error_log(2, iter) + (sum(curr_row) / (NObjects - 2));
            else
                acnt = acnt + 1;
                a_error_log(3, iter) = a_error_log(3, iter) + curr_row(diagonal_index);
                curr_row([diagonal_index, true_position]) = 0;
                a_error_log(4, iter) = a_error_log(4, iter) + (sum(curr_row) / (NObjects - 2));
            end
            
            % want to see evolution of pattern outputs
            logA{i} = [logA{i}; aData(i, :)]; % assume patterns in aData always appear in the same order
        end
        
        % average the results
        a_error_log(1, iter) = a_error_log(1, iter) / dcnt;
        a_error_log(2, iter) = a_error_log(2, iter) / dcnt;
        a_error_log(3, iter) = a_error_log(3, iter) / acnt;
        a_error_log(4, iter) = a_error_log(4, iter) / acnt;
        
        for i = 1:size(cData, 1)
            curr_row = cData(i, :);
            true_position = find(c_mse_position_patterns(i, :));
            diagonal_index = mod(true_position + (NPositions / 2), NPositions);
            if diagonal_index == 0
                diagonal_index = NPositions;
            end

            object_indices = find(c_mse_task_data(i, NPositions + 1:end));
            d_index = object_indices(1);

            if d_index == diagonal_index % A and B are diagonal
                c_error_log(1, iter) = c_error_log(1, iter) + curr_row(diagonal_index);
                curr_row([diagonal_index, true_position]) = 0;
                c_error_log(2, iter) = c_error_log(2, iter) + (sum(curr_row) / (NObjects - 2));
            else
                c_error_log(3, iter) = c_error_log(3, iter) + curr_row(diagonal_index);
                curr_row([diagonal_index, true_position]) = 0;
                c_error_log(4, iter) = c_error_log(4, iter) + (sum(curr_row) / (NObjects - 2));
            end
            
            % want to see evolution of pattern outputs
            logC{i} = [logC{i}; cData(i, :)];
        end
        
        % average the results
        c_error_log(1, iter) = c_error_log(1, iter) / dcnt;
        c_error_log(2, iter) = c_error_log(2, iter) / dcnt;
        c_error_log(3, iter) = c_error_log(3, iter) / acnt;
        c_error_log(4, iter) = c_error_log(4, iter) / acnt;

        for i = 1:size(eData, 1)
            curr_row = eData(i, :);
            true_position = find(e_mse_position_patterns(i, :));
            diagonal_index = mod(true_position + (NPositions / 2), NPositions);
            if diagonal_index == 0
                diagonal_index = NPositions;
            end

            object_indices = find(e_mse_task_data(i, NPositions + 1:end));
            f_index = object_indices(1);

            if f_index == diagonal_index % A and B are diagonal
                e_error_log(1, iter) = e_error_log(1, iter) + curr_row(diagonal_index);
                curr_row([diagonal_index, true_position]) = 0;
                e_error_log(2, iter) = e_error_log(2, iter) + (sum(curr_row) / (NObjects - 2));
            else
                e_error_log(3, iter) = e_error_log(3, iter) + curr_row(diagonal_index);
                curr_row([diagonal_index, true_position]) = 0;
                e_error_log(4, iter) = e_error_log(4, iter) + (sum(curr_row) / (NObjects - 2));
            end
            
            % want to see evolution of pattern outputs
            logE{i} = [logE{i}; eData(i, :)];
        end
        
        % average the results
        e_error_log(1, iter) = e_error_log(1, iter) / dcnt;
        e_error_log(2, iter) = e_error_log(2, iter) / dcnt;
        e_error_log(3, iter) = e_error_log(3, iter) / acnt;
        e_error_log(4, iter) = e_error_log(4, iter) / acnt;

        % get net data
        mse_log(iter) = chunkingNet.MSE_log(end);
        th_corr = corr(chunkingNet.weights.W_TH);
        for j = 1:NPositions
            diagonal_index = mod(j + (NPositions / 2), NPositions);
            if diagonal_index == 0
                diagonal_index = NPositions;
            end

            corr_trajectory(1, iter) = corr_trajectory(1, iter) + th_corr(j, NPositions + diagonal_index); % A-B diagonal
            corr_trajectory(2, iter) = corr_trajectory(2, iter) + th_corr((2 * NPositions) + j, (3 * NPositions) + diagonal_index); % C-D diagonal         
            
            b_indices = th_corr(j, (NPositions + 1):(2 * NPositions));
            corr_trajectory(3, iter) = corr_trajectory(3, iter) + sum(setdiff(b_indices, b_indices([j diagonal_index])));
        end
        
        corr_trajectory(1, iter) = corr_trajectory(1, iter) / NPositions;
        corr_trajectory(2, iter) = corr_trajectory(2, iter) / NPositions;
        corr_trajectory(3, iter) = corr_trajectory(3, iter) / (NPositions * (NPositions - 2));
        
        % create input data for chunking effect data collection
        chunk_object_patterns = zeros(NWorkingMemoryItems, NObjects);
        chunk_task_data = zeros(NWorkingMemoryItems, NWorkingMemoryItems);
        chunk_position_patterns = zeros(NWorkingMemoryItems, NPositions);
        
        pos = 1;
        obj = 1;
        for i = 1:NWorkingMemoryItems
            chunk_task_data(i, i) = 1;
            chunk_object_patterns(i, obj) = 1;
            chunk_position_patterns(i, pos) = 1;
            pos = pos + 1;
            if pos > NPositions
                pos = 1;
                obj = obj + 1;
            end
        end
        
        % run set
        [chunkData, chunkHidden, chunkMSE] = chunkingNet.runSet(chunk_object_patterns, chunk_task_data, chunk_position_patterns);
        
        % collect data
        for i = 1:size(chunkMSE, 1)
            chunk_effect(iter, i) = chunkMSE(i);
        end
        
        if (chunkingNet.MSE_log(end) <= thresh)
            corr_trajectory(1, iter:end) = corr_trajectory(1, iter);
            corr_trajectory(2, iter:end) = corr_trajectory(2, iter);
            corr_trajectory(3, iter:end) = corr_trajectory(3, iter);
            for i = 1:4
                a_error_log(i, iter:end) = a_error_log(i, iter);
                c_error_log(i, iter:end) = c_error_log(i, iter);
                e_error_log(i, iter:end) = e_error_log(i, iter);
            end
            
            for i = 1:(num_patterns / NObjects)
                matA = logA{i};
                extension = repmat(matA(end, :), [iterations_train - size(matA, 1), 1]);
                matA = [matA; extension];
                logA{i} = matA;
                
                matC = logC{i};
                extension = repmat(matC(end, :), [iterations_train - size(matC, 1), 1]);
                matC = [matC; extension];
                logC{i} = matC;
                
                matE = logE{i};
                extension = repmat(matE(end, :), [iterations_train - size(matE, 1), 1]);
                matE = [matE; extension];
                logE{i} = matE;
            end
            
            pattern_logs = [logA; logC; logE];
            training_error_logs = [a_error_log; c_error_log; e_error_log];
            
            for i = iter:iterations_train
                chunk_effect(i, :) = chunk_effect(iter, :);
            end
            
            break;
        end
    end
    disp(derp);
    derp = derp + 1;
    if (chunkingNet.MSE_log(end) <= thresh)
        break;
    end
end
%
%plot learning curve
figure(1)
plot(mse_log);
title('learning curve', 'FontSize', 16);
ylabel('MSE', 'FontSize', 16);
xlabel('training iterations', 'FontSize', 16);
%}
% create test data
% build the test set
% build the training set

test_task_data = zeros(num_patterns, NWorkingMemoryItems);
test_object_patterns = zeros(num_patterns, NObjects); 
test_position_patterns = zeros(num_patterns, NPositions);
num_del = 2;
for i = 1:num_patterns
    if rand < 0.8
        row = ceil(rand * (k - 1));
        test_task_data(i, :) = diag_task_data(row, :);
        test_object_patterns(i, :) = diag_object_patterns(row, :);
        test_position_patterns(i, :) = diag_position_patterns(row, :);

        % hacky way of randomly deleting two random working memory items:
        % randomly permute {1, ..., NObjects}, and delete the numbers
        % corresponding to the first num_del indices. Interpret 1 as A, 2 as B,
        % etc.
        delete_index = randperm(NObjects);
        count = 0;
        for j = 1:NWorkingMemoryItems
            if test_task_data(i, j) == 1
                count = count + 1;
                if ismember(count, delete_index(1:num_del)) == 1
                    test_task_data(i, j) = 0;
                end
            end
        end
    else
        row = ceil(rand * (l - 1));
        delete_index = randperm(NObjects);
        test_task_data(i, :) = adj_task_data(row, :);
        test_object_patterns(i, :) = adj_object_patterns(row, :);
        test_position_patterns(i, :) = adj_position_patterns(row, :);
        count = 0;
        for j = 1:NWorkingMemoryItems
            if test_task_data(i, j) == 1
                count = count + 1;
                if ismember(count, delete_index(1:num_del)) == 1
                    test_task_data(i, j) = 0;
                end
            end
        end
    end
end
  

% for i = 1:num_patterns
%     if rand < 0.8
%         row = ceil(rand * (k - 1));
%         test_task_data(i, :) = diag_task_data(row, :);
%         test_object_patterns(i, :) = diag_object_patterns(row, :);
%         test_position_patterns(i, :) = diag_position_patterns(row, :);
%     else
%         row = ceil(rand * (l - 1));
%         test_task_data(i, :) = adj_task_data(row, :);
%         test_object_patterns(i, :) = adj_object_patterns(row, :);
%         test_position_patterns(i, :) = adj_position_patterns(row, :);
%     end
% end

% compare learned output patterns with true output patterns
[outData, hiddenData, testMSE_del2] = chunkingNet.runSet(test_object_patterns, test_task_data, test_position_patterns);

test_task_data = zeros(num_patterns, NWorkingMemoryItems);
test_object_patterns = zeros(num_patterns, NObjects); 
test_position_patterns = zeros(num_patterns, NPositions);
num_del = 0;
for i = 1:num_patterns
    if rand < 0.8
        row = ceil(rand * (k - 1));
        test_task_data(i, :) = diag_task_data(row, :);
        test_object_patterns(i, :) = diag_object_patterns(row, :);
        test_position_patterns(i, :) = diag_position_patterns(row, :);

        % hacky way of randomly deleting two random working memory items:
        % randomly permute {1, ..., NObjects}, and delete the numbers
        % corresponding to the first num_del indices. Interpret 1 as A, 2 as B,
        % etc.
        delete_index = randperm(NObjects);
        count = 0;
        for j = 1:NWorkingMemoryItems
            if test_task_data(i, j) == 1
                count = count + 1;
                if ismember(count, delete_index(1:num_del)) == 1
                    test_task_data(i, j) = 0;
                end
            end
        end
    else
        row = ceil(rand * (l - 1));
        delete_index = randperm(NObjects);
        test_task_data(i, :) = adj_task_data(row, :);
        test_object_patterns(i, :) = adj_object_patterns(row, :);
        test_position_patterns(i, :) = adj_position_patterns(row, :);
        count = 0;
        for j = 1:NWorkingMemoryItems
            if test_task_data(i, j) == 1
                count = count + 1;
                if ismember(count, delete_index(1:num_del)) == 1
                    test_task_data(i, j) = 0;
                end
            end
        end
    end
end

[outData, hiddenData, testMSE_del0] = chunkingNet.runSet(test_object_patterns, test_task_data, test_position_patterns);

test_task_data = zeros(num_patterns, NWorkingMemoryItems);
test_object_patterns = zeros(num_patterns, NObjects); 
test_position_patterns = zeros(num_patterns, NPositions);
num_del = 1;
for i = 1:num_patterns
    if rand < 0.8
        row = ceil(rand * (k - 1));
        test_task_data(i, :) = diag_task_data(row, :);
        test_object_patterns(i, :) = diag_object_patterns(row, :);
        test_position_patterns(i, :) = diag_position_patterns(row, :);

        % hacky way of randomly deleting two random working memory items:
        % randomly permute {1, ..., NObjects}, and delete the numbers
        % corresponding to the first num_del indices. Interpret 1 as A, 2 as B,
        % etc.
        delete_index = randperm(NObjects);
        count = 0;
        for j = 1:NWorkingMemoryItems
            if test_task_data(i, j) == 1
                count = count + 1;
                if ismember(count, delete_index(1:num_del)) == 1
                    test_task_data(i, j) = 0;
                end
            end
        end
    else
        row = ceil(rand * (l - 1));
        delete_index = randperm(NObjects);
        test_task_data(i, :) = adj_task_data(row, :);
        test_object_patterns(i, :) = adj_object_patterns(row, :);
        test_position_patterns(i, :) = adj_position_patterns(row, :);
        count = 0;
        for j = 1:NWorkingMemoryItems
            if test_task_data(i, j) == 1
                count = count + 1;
                if ismember(count, delete_index(1:num_del)) == 1
                    test_task_data(i, j) = 0;
                end
            end
        end
    end
end

[outData, hiddenData, testMSE_del1] = chunkingNet.runSet(test_object_patterns, test_task_data, test_position_patterns);


%{
figure(2);
subplot(1,2,1)
imagesc(test_position_patterns);
title('true positions of objects', 'FontSize', 16);
ylabel('patterns', 'FontSize', 16);
xlabel('positions', 'FontSize', 16);
subplot(1,2,2)
imagesc(outData);
title('learned positions of objects', 'FontSize', 16);
ylabel('patterns', 'FontSize', 16);
xlabel('positions', 'FontSize', 16);
set(gcf, 'Color', 'w');
%}

%{
figure(3);
title('correlation for dependent and independent pairs', 'FontSize', 16);
boxplot(corr_pairs);
%}
% MSE testing
a_mse_object_patterns = [];
a_mse_position_patterns = [];
a_mse_task_data = [];
b_mse_object_patterns = [];
b_mse_position_patterns = [];
b_mse_task_data = [];
c_mse_object_patterns = [];
c_mse_position_patterns = [];
c_mse_task_data = [];
d_mse_object_patterns = [];
d_mse_position_patterns = [];
d_mse_task_data = [];
%
e_mse_object_patterns = [];
e_mse_position_patterns = [];
e_mse_task_data = [];
f_mse_object_patterns = [];
f_mse_position_patterns = [];
f_mse_task_data = [];
%}
% going to do this in a dumb way for the sake of just getting it done
for i = 1:size(diag_object_patterns)
    if diag_object_patterns(i, 1) == 1
        a_mse_object_patterns = [a_mse_object_patterns;diag_object_patterns(i, :)];
        a_mse_task_data = [a_mse_task_data;diag_task_data(i, :)];
        a_mse_position_patterns = [a_mse_position_patterns;diag_position_patterns(i, :)];
    elseif diag_object_patterns(i, 2) == 1
        b_mse_object_patterns = [b_mse_object_patterns;diag_object_patterns(i, :)];
        b_mse_task_data = [b_mse_task_data;diag_task_data(i, :)];
        b_mse_position_patterns = [b_mse_position_patterns;diag_position_patterns(i, :)];
    elseif diag_object_patterns(i, 3) == 1
        c_mse_object_patterns = [c_mse_object_patterns;diag_object_patterns(i, :)];
        c_mse_task_data = [c_mse_task_data;diag_task_data(i, :)];
        c_mse_position_patterns = [c_mse_position_patterns;diag_position_patterns(i, :)];
    elseif diag_object_patterns(i, 4) == 1
        d_mse_object_patterns = [d_mse_object_patterns;diag_object_patterns(i, :)];
        d_mse_task_data = [d_mse_task_data;diag_task_data(i, :)];
        d_mse_position_patterns = [d_mse_position_patterns;diag_position_patterns(i, :)];
    %
    elseif diag_object_patterns(i, 5) == 1
        e_mse_object_patterns = [e_mse_object_patterns;diag_object_patterns(i, :)];
        e_mse_task_data = [e_mse_task_data;diag_task_data(i, :)];
        e_mse_position_patterns = [e_mse_position_patterns;diag_position_patterns(i, :)];
    else
        f_mse_object_patterns = [f_mse_object_patterns;diag_object_patterns(i, :)];
        f_mse_task_data = [f_mse_task_data;diag_task_data(i, :)];
        f_mse_position_patterns = [f_mse_position_patterns;diag_position_patterns(i, :)];
    %}
    end
end

for i = 1:size(adj_object_patterns)
    if adj_object_patterns(i, 1) == 1
        a_mse_object_patterns = [a_mse_object_patterns;adj_object_patterns(i, :)];
        a_mse_task_data = [a_mse_task_data;adj_task_data(i, :)];
        a_mse_position_patterns = [a_mse_position_patterns;adj_position_patterns(i, :)];
    elseif adj_object_patterns(i, 2) == 1
        b_mse_object_patterns = [b_mse_object_patterns;adj_object_patterns(i, :)];
        b_mse_task_data = [b_mse_task_data;adj_task_data(i, :)];
        b_mse_position_patterns = [b_mse_position_patterns;adj_position_patterns(i, :)];
    elseif adj_object_patterns(i, 3) == 1
        c_mse_object_patterns = [c_mse_object_patterns;adj_object_patterns(i, :)];
        c_mse_task_data = [c_mse_task_data;adj_task_data(i, :)];
        c_mse_position_patterns = [c_mse_position_patterns;adj_position_patterns(i, :)];
    elseif adj_object_patterns(i, 4) == 1
        d_mse_object_patterns = [d_mse_object_patterns;adj_object_patterns(i, :)];
        d_mse_task_data = [d_mse_task_data;adj_task_data(i, :)];
        d_mse_position_patterns = [d_mse_position_patterns;adj_position_patterns(i, :)];
    %
    elseif adj_object_patterns(i, 5) == 1
        e_mse_object_patterns = [e_mse_object_patterns;adj_object_patterns(i, :)];
        e_mse_task_data = [e_mse_task_data;adj_task_data(i, :)];
        e_mse_position_patterns = [e_mse_position_patterns;adj_position_patterns(i, :)];
    else
        f_mse_object_patterns = [f_mse_object_patterns;adj_object_patterns(i, :)];
        f_mse_task_data = [f_mse_task_data;adj_task_data(i, :)];
        f_mse_position_patterns = [f_mse_position_patterns;adj_position_patterns(i, :)];
    %}
    end
end

[aData, aHidden, aMSE] = chunkingNet.runSet(a_mse_object_patterns, a_mse_task_data, a_mse_position_patterns);
[bData, bHidden, bMSE] = chunkingNet.runSet(b_mse_object_patterns, b_mse_task_data, b_mse_position_patterns);
[cData, cHidden, cMSE] = chunkingNet.runSet(c_mse_object_patterns, c_mse_task_data, c_mse_position_patterns);
[dData, dHidden, dMSE] = chunkingNet.runSet(d_mse_object_patterns, d_mse_task_data, d_mse_position_patterns);
%
[eData, eHidden, eMSE] = chunkingNet.runSet(e_mse_object_patterns, e_mse_task_data, e_mse_position_patterns);
[fData, fHidden, fMSE] = chunkingNet.runSet(f_mse_object_patterns, f_mse_task_data, f_mse_position_patterns);
%}

%avg_mse = [mean(aMSE); mean(bMSE); mean(cMSE); mean(dMSE);];
avg_mse = [mean(aMSE); mean(bMSE); mean(cMSE); mean(dMSE); mean(eMSE); mean(fMSE)];

%{
diag_diag_error = 0;
diag_adj_error = 0;
adj_diag_error = 0;
adj_adj_error = 0;
diag_cnt = 0;
adj_cnt = 0;
for i = 1:size(aData, 1)
    curr_row = aData(i, :);
    true_position = find(a_mse_position_patterns(i, :));
    diagonal_index = mod(true_position + (NPositions / 2), NPositions);
    if diagonal_index == 0
        diagonal_index = NPositions;
    end
    
    object_indices = find(a_mse_task_data(i, NPositions + 1:end));
    b_index = object_indices(1);
    
    if b_index == diagonal_index % A and B are diagonal
        diag_cnt = diag_cnt + 1;
        diag_diag_error = diag_diag_error + curr_row(diagonal_index);
        curr_row([diagonal_index, true_position]) = 0;
        diag_adj_error = diag_adj_error + sum(curr_row);
    else
        adj_cnt = adj_cnt + 1;
        adj_diag_error = adj_diag_error + curr_row(diagonal_index);
        curr_row([diagonal_index, true_position]) = 0;
        adj_adj_error = adj_adj_error + sum(curr_row);
    end
end

diag_diag_error = diag_diag_error / diag_cnt;
diag_adj_error = diag_adj_error / (adj_cnt * (NObjects - 2));
adj_diag_error = adj_diag_error / diag_cnt;
adj_adj_error = adj_adj_error / (adj_cnt * (NObjects - 2));

error_vals = [diag_diag_error; diag_adj_error; adj_diag_error; adj_adj_error];
%}

weight_corr_pairs = corr(chunkingNet.weights.W_TH);

end
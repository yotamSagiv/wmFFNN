NPositions = 6;
NObjects = 6;

num_patterns = 4320;
num_diag_patterns = num_patterns / (NPositions - 1);

diag_task_data = zeros(num_diag_patterns, NWorkingMemoryItems); % each row is a training trial, 1 for the presented object-location pair, 0 otherwise
diag_object_patterns = zeros(num_diag_patterns, NObjects); % each row is a training trial, 1 for the cued object, 0 otherwise
diag_position_patterns = zeros(num_diag_patterns, NPositions); % each row is a training trial, 1 for the object location, 0 otherwise

adj_task_data = zeros(num_patterns - num_diag_patterns, NWorkingMemoryItems);
adj_object_patterns = zeros(num_patterns - num_diag_patterns, NObjects);
adj_position_patterns = zeros(num_patterns - num_diag_patterns, NPositions);

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
    
    % dealing with the fact that MATLAB is 1-indexed...
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

a_mse_object_patterns = [];
a_mse_position_patterns = [];
a_mse_task_data = [];
c_mse_object_patterns = [];
c_mse_position_patterns = [];
c_mse_task_data = [];
e_mse_object_patterns = [];
e_mse_position_patterns = [];
e_mse_task_data = [];

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

disp(isequal(a_mse_task_data, c_mse_task_data, e_mse_task_data));

dlmwrite('permutation_table.txt', a_mse_task_data);
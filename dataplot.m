%% Read data

num_patterns = 4320;
iterations_train = 2000;
num_iterations = 100;
num_bad_iterations = 0;
NWorkingMemoryItems = 36;
NObjects = 6;
NPositions = 6;
dir = './';

a_mse = dlmread(strcat(dir, 'a_mse.txt'), ',');
b_mse = dlmread(strcat(dir, 'b_mse.txt'), ',');
c_mse = dlmread(strcat(dir, 'c_mse.txt'), ',');
d_mse = dlmread(strcat(dir, 'd_mse.txt'), ',');
e_mse = dlmread(strcat(dir, 'e_mse.txt'), ',');
f_mse = dlmread(strcat(dir, 'f_mse.txt'), ',');

a_error_log = dlmread(strcat(dir, 'a_error_log.txt'), ',');
c_error_log = dlmread(strcat(dir, 'c_error_log.txt'), ',');
e_error_log = dlmread(strcat(dir, 'e_error_log.txt'), ',');

weight_corr_vals = dlmread(strcat(dir, 'weight_corrs.txt'), ',');
weight_corrs = [];
%
diag_corr_traj = dlmread(strcat(dir, 'diag_corr_traj.txt'), ',');
adj_corr_traj = dlmread(strcat(dir, 'adj_corr_traj.txt'), ',');
ab_adj_corr_traj = dlmread(strcat(dir, 'ab_adj_corr_traj.txt'), ',');

mse_log = dlmread(strcat(dir, 'mse_log.txt'), ',');

chunk_effect = dlmread(strcat(dir, 'chunk_effect.txt'), ',');

% process weight_corr_vals into something analyzable
% because i screwed up the first run of this script, the (1 / i) is
% necessary.
% please remove in subsequent uses.
% kthx.
for i = 1:num_iterations
    if i <= num_bad_iterations
        weight_corrs = cat(3, weight_corrs, (1 / i) .* weight_corr_vals((((i - 1) * NWorkingMemoryItems) + 1):(((i - 1) * NWorkingMemoryItems) + NWorkingMemoryItems), :));
    else
        weight_corrs = cat(3, weight_corrs, weight_corr_vals((((i - 1) * NWorkingMemoryItems) + 1):(((i - 1) * NWorkingMemoryItems) + NWorkingMemoryItems), :));
    end
end

%% correlation matrix
figure(1)
imagesc(mean(weight_corrs, 3));
set(gca, 'xtick', 1:NWorkingMemoryItems, 'xticklabel', {'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'F1', 'F2', 'F3', 'F4', 'F5', 'F6'});
set(gca, 'ytick', 1:NWorkingMemoryItems, 'yticklabel', {'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'F1', 'F2', 'F3', 'F4', 'F5', 'F6'});
colorbar;
title('Avg task-hidden weight correlations for working memory items');

%% diagonal vs adjacent correlation
abcd_diag_corr = zeros(num_iterations, 2);
for i = 1:size(weight_corrs, 3)
    for j = 1:NPositions
        diagonal_index = mod(j + (NPositions / 2), NPositions);
        if diagonal_index == 0
            diagonal_index = NPositions;
        end
        
        abcd_diag_corr(i, 1) = abcd_diag_corr(i, 1) + weight_corrs(j, NPositions + diagonal_index, i);
        abcd_diag_corr(i, 2) = abcd_diag_corr(i, 2) + weight_corrs((2 * NPositions) + j, (3 * NPositions) + diagonal_index, i);
    end
end

abcd_diag_corr = abcd_diag_corr ./ NPositions;

figure(2)
boxplot(abcd_diag_corr);
set(gca, 'xtick', 1:2, 'xticklabel', {'A/B', 'C/D'});
xlabel('Stimulus pair');
ylabel('Correlation');
title('Avg correlation for A/B and C/D diagonal configs');

%% avg mse for stimuli
figure(3)
data = [a_mse b_mse c_mse d_mse e_mse f_mse];
boxplot(data);
set(gca, 'xtick', 1:NObjects, 'xticklabel', {'A', 'B', 'C', 'D', 'E', 'F'});
xlabel('Stimulus picked');
ylabel('MSE');
title('Avg MSE for stimuli across all object configurations');

%% behavioural error
a_diag_diag = a_error_log(1:4:end, :);
a_diag_adj = a_error_log(2:4:end, :);
a_adj_diag = a_error_log(3:4:end, :);
a_adj_adj = a_error_log(4:4:end, :);
c_diag_diag = c_error_log(1:4:end, :);
c_diag_adj = c_error_log(2:4:end, :);
c_adj_diag = c_error_log(3:4:end, :);
c_adj_adj = c_error_log(4:4:end, :);
e_diag_diag = e_error_log(1:4:end, :);
e_diag_adj = e_error_log(2:4:end, :);
e_adj_diag = e_error_log(3:4:end, :);
e_adj_adj = e_error_log(4:4:end, :);

figure(4)
data = [a_diag_diag(:, end) a_diag_adj(:, end) a_adj_diag(:, end) a_adj_adj(:, end)];
data = [data c_diag_diag(:, end) c_diag_adj(:, end) c_adj_diag(:, end) c_adj_adj(:, end)];
data = [data e_diag_diag(:, end) e_diag_adj(:, end) e_adj_diag(:, end) e_adj_adj(:, end)];
boxplot(data);
set(gca, 'xtick', 1:12, 'xticklabel', {'DD', 'DA', 'AD', 'AA', 'DD', 'DA', 'AD', 'AA', 'DD', 'DA', 'AD', 'AA'});
xlabel('Configuration type');
ylabel('Error');
title('Error for diagonal vs adjacent configurations, stimulus = A');

figure(5)
x = [1:2000];
subplot(1, 3, 1);
hold on;
handle1 = plot(x, mean(a_diag_diag));
handle2 = plot(x, mean(a_diag_adj));
handle3 = plot(x, mean(a_adj_diag));
handle4 = plot(x, mean(a_adj_adj));
legend([handle1; handle2; handle3; handle4], ['DD'; 'DA'; 'AD'; 'AA']);
hold off;
ylabel('Error');

subplot(1, 3, 2);
hold on;
handle1 = plot(x, mean(c_diag_diag));
handle2 = plot(x, mean(c_diag_adj));
handle3 = plot(x, mean(c_adj_diag));
handle4 = plot(x, mean(c_adj_adj));
legend([handle1; handle2; handle3; handle4], ['DD'; 'DA'; 'AD'; 'AA']);
hold off;
xlabel('Training iteration');
title('Error trajectory for various error conditions');

subplot(1, 3, 3);
hold on;
handle1 = plot(x, mean(e_diag_diag));
handle2 = plot(x, mean(e_diag_adj));
handle3 = plot(x, mean(e_adj_diag));
handle4 = plot(x, mean(e_adj_adj));
legend([handle1; handle2; handle3; handle4], ['DD'; 'DA'; 'AD'; 'AA']);
hold off;

%% correlation trajectory
figure(6)
hold on
yyaxis left;
x = [1:2000];
handle1 = plot(x, mean(diag_corr_traj), 'LineWidth', 2);
handle2 = plot(x, mean(adj_corr_traj), 'LineWidth', 2);
handle4 = plot(x, mean(ab_adj_corr_traj), 'LineWidth', 2);
ylabel('Correlation');
hold off
yyaxis right;
handle3 = plot(x, mean(mse_log), 'LineWidth', 2);
legend([handle1; handle2; handle3; handle4], {'A/B'; 'C/D'; 'MSE'; 'A/B adj'});
ylabel('MSE');
xlabel('Training iteration');
title('Correlation trajectories during training');
set(gca, 'FontSize', 12);

%% pattern error trajectory
poi = [2 5 6 1 3 4]; % poi = pattern of interest

data_row = zeros(1, NWorkingMemoryItems);
    
% convert permutation to a task layer (e.g. [1 2 3 4 5 6] to [1 0 0...]
for j = 1:NObjects
   index = ((j - 1) * NObjects) + poi(j);
   data_row(index) = 1;
end

permutation_table = dlmread('permutation_table.txt', ',');
[tf, poi_index_vect] = ismember(permutation_table, data_row, 'rows');
poi_index = find(poi_index_vect);

%% read pattern log files
logA = [];
logC = [];
logE = [];
for i = 1:10
    disp(i);
    curr_p_log = load(strcat('pattern_logs_t', num2str(i), '.mat'), 'p_logs');
    logA = [logA; curr_p_log.p_logs(1:3:end, :)];
    logC = [logC; curr_p_log.p_logs(2:3:end, :)];
    logE = [logE; curr_p_log.p_logs(3:3:end, :)];
    disp(i);
end
%%
for i = 1:(num_patterns / NObjects) % number of patterns for a given stimulus = num_patterns / NObjects
    apl{i} = zeros(iterations_train, NPositions); % apl = a pattern log
    cpl{i} = zeros(iterations_train, NPositions); % cpl = c pattern log
    epl{i} = zeros(iterations_train, NPositions); % epl = e pattern log
end 
disp('done empty init');
%%
for i = 1:size(logA, 1)
    disp(i);
    curr_logA = logA(i, :);
    curr_logC = logC(i, :);
    curr_logE = logE(i, :);
    for j = 1:size(curr_logA, 2)
        a_mat = apl{j};
        a_mat = a_mat + curr_logA{j};
        apl{j} = a_mat;
        
        c_mat = cpl{j};
        c_mat = c_mat + curr_logC{j};
        cpl{j} = c_mat;
        
        e_mat = epl{j};
        e_mat = e_mat + curr_logE{j};
        epl{j} = e_mat;
    end
end
disp('done concats');
%%
for i = 1:size(apl, 2)
    apl{i} = apl{i} / num_iterations;
    cpl{i} = cpl{i} / num_iterations;
    epl{i} = epl{i} / num_iterations;
    disp(i);
end

%% plot heatmaps
figure(7)
subplot(1,2,1);
imagesc(transpose(mean(diag_corr_traj(:, 1:300))));
subplot(1,2,2);
data_mat = apl{poi_index};
imagesc(data_mat(1:300, :));

%% error over training per stimulus location
num_diag_patterns = num_patterns / ((NPositions - 1) * NObjects); % number of diagonal patterns for a stimulus
object_pattern_traj = zeros(iterations_train, NPositions, num_diag_patterns);
num_adj_patterns = (num_patterns / (NObjects)) - num_diag_patterns;
adj_pattern_traj = zeros(iterations_train, NPositions, num_adj_patterns);

for i = 1:num_diag_patterns
    curr_pattern = apl{i};
    data_row = permutation_table(i, :);
    for j = 1:NPositions
        obj_position = find(data_row(((j - 1) * NPositions + 1):(j * NPositions)));
        object_pattern_traj(:, j, i) = curr_pattern(:, obj_position);
    end
end

for i = 1:num_adj_patterns
    offset = num_diag_patterns;
    curr_pattern = apl{i + offset};
    data_row = permutation_table(i + offset, :);
    for j = 1:NPositions
        obj_position = find(data_row(((j - 1) * NPositions + 1):(j * NPositions)));
        adj_pattern_traj(:, j, i) = curr_pattern(:, obj_position);
    end
end

object_pattern_traj = mean(object_pattern_traj, 3);
adj_pattern_traj = mean(adj_pattern_traj, 3);

figure(8)
subplot(1,2,1);
imagesc(transpose(mean(diag_corr_traj(:, 1:300))));
colorbar;
ylabel('Training iteration');
title('Correlation');
set(gca, 'xtick', []);
subplot(1,2,2);
imagesc(object_pattern_traj(1:300, :));
xlabel('Position');
ylabel('Training iteration');
title('Error');
set(gca, 'xtick', 1:6, 'xticklabel', {'A', 'B', 'C', 'D', 'E', 'F'});

figure(9)
ax = subplot(1,2,1);
imagesc(transpose(mean(ab_adj_corr_traj(:, 1:300))));
cmap = colormap;
cmapf = flipud(cmap);
colormap(ax, cmapf);
ylabel('Training iteration');
title('Correlation');
set(gca, 'xtick', []);
colorbar;
subplot(1,2,2);
imagesc(adj_pattern_traj(1:300, :));
xlabel('Position');
ylabel('Training iteration');
colorbar;
title('Error');
set(gca, 'xtick', 1:6, 'xticklabel', {'A', 'B', 'C', 'D', 'E', 'F'});

%%

figure(10)
chunk_effect_data = zeros(iterations_train, NWorkingMemoryItems, num_iterations);
for i = 1:num_iterations
    chunk_effect_data(:, :, i) = chunk_effect(((i-1) * iterations_train + 1) : (i * iterations_train));
end

chunk_effect_data = mean(chunk_effect_data, 3);
imagesc(chunk_effect_data);

num_iterations = 10;
dir = '../chunking_sim/';

for i=1:num_iterations
    disp(i);
    
    [mse_log, weight_corr_pairs, corr_trajectory] = chunking_sim(6,4,2);
  
    dlmwrite(strcat(dir, 'mse_log.txt'), mse_log, '-append');
    
    dlmwrite(strcat(dir, 'weight_corr_pairs.txt'), weight_corr_pairs, '-append');
  
    dlmwrite(strcat(dir, 'pattern_corr_traj.txt'), corr_trajectory(1, :), '-append');
    dlmwrite(strcat(dir, 'antipattern_corr_traj.txt'), corr_trajectory(2, :), '-append');
    
    disp(i);
end
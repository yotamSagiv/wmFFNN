num_iterations = 10;
dir = '../chunk_effect/';

p_logs = [];

for i=1:num_iterations
    disp(i);
    
    [mse, weight_corr_pairs, corr_trajectory, mse_log, error_logs, pattern_logs, chunk_effect] = chunking_sim_stat_del(6,6,0);
    
    dlmwrite(strcat(dir, 'a_mse.txt'), mse(1), '-append');
    dlmwrite(strcat(dir, 'b_mse.txt'), mse(2), '-append');
    dlmwrite(strcat(dir, 'c_mse.txt'), mse(3), '-append');
    dlmwrite(strcat(dir, 'd_mse.txt'), mse(4), '-append');
    dlmwrite(strcat(dir, 'e_mse.txt'), mse(5), '-append');
    dlmwrite(strcat(dir, 'f_mse.txt'), mse(6), '-append');

    weight_corrs = weight_corr_pairs;
    dlmwrite(strcat(dir, 'weight_corrs.txt'), weight_corrs, '-append');
    
    dlmwrite(strcat(dir, 'a_error_log.txt'), error_logs(1:4, :), '-append');
    dlmwrite(strcat(dir, 'c_error_log.txt'), error_logs(5:8, :), '-append');
    dlmwrite(strcat(dir, 'e_error_log.txt'), error_logs(9:12, :), '-append');
    
    dlmwrite(strcat(dir, 'diag_corr_traj.txt'), corr_trajectory(1, :), '-append');
    dlmwrite(strcat(dir, 'adj_corr_traj.txt'), corr_trajectory(2, :), '-append');
    dlmwrite(strcat(dir, 'ab_adj_corr_traj.txt'), corr_trajectory(3, :), '-append');
    dlmwrite(strcat(dir, 'mse_log.txt'), mse_log, '-append');
    
    if i ~= 1
        clear('p_logs');
        load(strcat(dir, 'pattern_logs.mat'), 'p_logs');
    end
    
    p_logs = [p_logs; pattern_logs];
    save(strcat(dir, 'pattern_logs.mat'), 'p_logs');
    
    dlmwrite(strcat(dir, 'chunk_effect.txt'), chunk_effect, '-append');
    
    disp(i);
end
dir = '../error_log/';
p_logs = [];

for i = 1:10
    a_mse = dlmread(strcat(dir, 't', num2str(i), '/a_mse.txt'), ',');
    b_mse = dlmread(strcat(dir, 't', num2str(i), '/b_mse.txt'), ',');
    c_mse = dlmread(strcat(dir, 't', num2str(i), '/c_mse.txt'), ',');
    d_mse = dlmread(strcat(dir, 't', num2str(i), '/d_mse.txt'), ',');
    e_mse = dlmread(strcat(dir, 't', num2str(i), '/e_mse.txt'), ',');
    f_mse = dlmread(strcat(dir, 't', num2str(i), '/f_mse.txt'), ',');

    a_error_log = dlmread(strcat(dir, 't', num2str(i), '/a_error_log.txt'), ',');
    c_error_log = dlmread(strcat(dir, 't', num2str(i), '/c_error_log.txt'), ',');
    e_error_log = dlmread(strcat(dir, 't', num2str(i), '/e_error_log.txt'), ',');

    weight_corr_vals = dlmread(strcat(dir, 't', num2str(i), '/weight_corrs.txt'), ',');
    %
    diag_corr_traj = dlmread(strcat(dir, 't', num2str(i), '/diag_corr_traj.txt'), ',');
    ab_adj_corr_traj = dlmread(strcat(dir, 't', num2str(i), '/ab_adj_corr_traj.txt'), ',');
    adj_corr_traj = dlmread(strcat(dir, 't', num2str(i), '/adj_corr_traj.txt'), ',');

    mse_log = dlmread(strcat(dir, 't', num2str(i), '/mse_log.txt'), ',');
    %}
    
    %{
    curr_p_log = load(strcat(dir, 't', num2str(i), '/pattern_logs.mat'), 'p_logs');
    if (i ~= 1)
        p_log_struct = matfile(strcat(dir, 'data', '/pattern_logs.mat'), 'p_logs');
        p_log_struct.p_logs = [p_log_struct.p_logs; curr_p_log.p_logs];
        %p_logs = [p_log_struct.p_logs; curr_p_log.p_logs];
    else
        p_logs = [curr_p_log.p_logs];
    end
    %}
    
    dlmwrite(strcat(dir, 'data/a_mse.txt'), a_mse, '-append');
    dlmwrite(strcat(dir, 'data/b_mse.txt'), b_mse, '-append');
    dlmwrite(strcat(dir, 'data/c_mse.txt'), c_mse, '-append');
    dlmwrite(strcat(dir, 'data/d_mse.txt'), d_mse, '-append');
    dlmwrite(strcat(dir, 'data/e_mse.txt'), e_mse, '-append');
    dlmwrite(strcat(dir, 'data/f_mse.txt'), f_mse, '-append');
    
    dlmwrite(strcat(dir, 'data/a_error_log.txt'), a_error_log, '-append');
    dlmwrite(strcat(dir, 'data/c_error_log.txt'), c_error_log, '-append');
    dlmwrite(strcat(dir, 'data/e_error_log.txt'), e_error_log, '-append');
    
    dlmwrite(strcat(dir, 'data/weight_corrs.txt'), weight_corr_vals, '-append');
    
    dlmwrite(strcat(dir, 'data/diag_corr_traj.txt'), diag_corr_traj, '-append');
    dlmwrite(strcat(dir, 'data/ab_adj_corr_traj.txt'), ab_adj_corr_traj, '-append');
    dlmwrite(strcat(dir, 'data/adj_corr_traj.txt'), adj_corr_traj, '-append');
    
    dlmwrite(strcat(dir, 'data/mse_log.txt'), mse_log, '-append');
    
    %save(strcat(dir, 'data/pattern_logs.mat'), 'p_logs', '-v7.3');
end
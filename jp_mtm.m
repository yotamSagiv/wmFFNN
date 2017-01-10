for i = 1:50
    [testMSE_del2, testMSE_del1, testMSE_del0, avg_mse, weight_corr_pairs, corr_trajectory, mse_log, training_error_logs, pattern_logs, chunk_effect] = chunking_sim_stat_del(6, 6, 0, 1);

    if i == 1
        mse_del0 = testMSE_del0;
        mse_del1 = testMSE_del1;
        mse_del2 = testMSE_del2;
    else
        mse_del0 = cat(3, mse_del0, testMSE_del0);
        mse_del1 = cat(3, mse_del1, testMSE_del1);
        mse_del2 = cat(3, mse_del2, testMSE_del2);
    end
    disp(i);
end

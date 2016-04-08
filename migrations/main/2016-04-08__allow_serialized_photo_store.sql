UPDATE jq_subtask_config SET step_num = step_num + 1000000 WHERE queue_name = 'mls' AND step_num > 4 AND step_num < 10;

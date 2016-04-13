UPDATE jq_subtask_config SET step_num = step_num + 1000000 WHERE task_name = 'blackknight' AND step_num > 2 AND step_num < 10;

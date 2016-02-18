UPDATE jq_subtask_config SET hard_fail_timeouts = FALSE WHERE task_name = 'blackknight';
UPDATE jq_subtask_config SET warn_timeout_seconds = 120, kill_timeout_seconds = 150 WHERE name = 'blackknight_deleteData';

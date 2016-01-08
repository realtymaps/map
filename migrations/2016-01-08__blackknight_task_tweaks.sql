UPDATE jq_task_config
SET warn_timeout_minutes = 240, kill_timeout_minutes = 300, active = TRUE
WHERE name = 'blackknight';

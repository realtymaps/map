
UPDATE jq_subtask_config SET task_name = 'blackknight' WHERE name = 'blackknight_checkFtpDrop';
UPDATE jq_task_config SET repeat_period_minutes = '60' WHERE name = 'blackknight';

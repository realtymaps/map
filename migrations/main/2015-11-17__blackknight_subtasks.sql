
UPDATE jq_subtask_config SET kill_timeout_seconds = '900', warn_timeout_seconds = '840' WHERE name = 'blackknight_loadRawData';
UPDATE jq_task_config SET warn_timeout_minutes = '60', kill_timeout_minutes = '75' WHERE name = 'blackknight';

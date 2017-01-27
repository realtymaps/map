
TRUNCATE jq_current_subtasks;
DELETE FROM jq_task_history WHERE current = TRUE;

DELETE FROM jq_task_config WHERE name = 'cleanup_deleteInactiveRows';

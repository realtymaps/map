
UPDATE jq_task_config
SET name = 'cartodb'
WHERE name = 'cartodb_wake';

UPDATE jq_subtask_config
SET name = 'cartodb_wake', task_name = 'cartodb', queue_name = 'misc'
WHERE name = 'wake';

DELETE FROM jq_queue_config
WHERE name = 'cartodb';

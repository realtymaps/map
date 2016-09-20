UPDATE jq_task_config
SET repeat_period_minutes = '5'
WHERE name = 'digimaps';

UPDATE jq_subtask_config
SET
  name = 'digimaps_cleanup',
  auto_enqueue = FALSE
WHERE name = 'digimaps_releaseExclusiveAccess';

UPDATE jq_subtask_config
SET auto_enqueue = FALSE
WHERE name = 'digimaps_waitForExclusiveAccess';

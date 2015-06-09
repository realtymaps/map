UPDATE jq_task_config
  SET name = 'swflmls'
  WHERE name = 'mls_swfl';

UPDATE jq_subtask_config
SET task_name = 'swflmls'
WHERE task_name = 'mls_swfl';

UPDATE jq_subtask_config
  SET step_num = '5', auto_enqueue = FALSE
  WHERE name = 'finalizeData';

UPDATE jq_subtask_config
  SET step_num = '6', auto_enqueue = FALSE
  WHERE name = 'removeExtraRows';

UPDATE jq_subtask_config
SET name = 'recordChangeCounts'
WHERE task_name = 'swflmls' AND name = 'markDeleted';


INSERT INTO jq_subtask_config (
  name,
  task_name,
  queue_name,
  step_num,
  retry_max_count,
  hard_fail_timeouts,
  hard_fail_after_retries,
  hard_fail_zombies,
  warn_timeout_seconds,
  kill_timeout_seconds,
  auto_enqueue
) VALUES (
  'finalizeDataPrep',
  'swflmls',
  'mls',
  '4',
  '0',
  TRUE,
  TRUE,
  TRUE,
  20,
  30,
  TRUE
);

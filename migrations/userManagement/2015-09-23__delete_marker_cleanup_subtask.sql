
INSERT INTO jq_subtask_config (
  name,
  task_name,
  queue_name,
  step_num,
  retry_delay_seconds,
  retry_max_count,
  hard_fail_timeouts,
  hard_fail_after_retries,
  hard_fail_zombies,
  warn_timeout_seconds,
  kill_timeout_seconds,
  auto_enqueue
) VALUES (
  'cleanup_deleteMarkers',
  'cleanup',
  'misc',
  '1',
  '30',
  '2',
  TRUE,
  TRUE,
  TRUE,
  30,
  60,
  TRUE
);

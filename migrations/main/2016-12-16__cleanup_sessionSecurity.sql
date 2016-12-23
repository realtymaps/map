INSERT INTO jq_subtask_config (
  name,
  task_name,
  queue_name,
  data,
  step_num,
  retry_max_count,
  auto_enqueue,
  active,
  retry_delay_minutes,
  kill_timeout_minutes,
  warn_timeout_minutes
) VALUES (
  'cleanup_sessionSecurity',
  'cleanup',
  'misc',
  NULL,
  10,
  2,
  TRUE,
  TRUE,
  1,
  NULL,
  2
);

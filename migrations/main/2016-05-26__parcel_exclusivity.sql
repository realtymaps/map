UPDATE jq_subtask_config SET step_num = step_num + 1 WHERE step_num >= 10006;

INSERT INTO jq_subtask_config (
  name,
  task_name,
  queue_name,
  step_num,
  data,
  retry_delay_seconds,
  retry_max_count,
  hard_fail_timeouts,
  hard_fail_after_retries,
  hard_fail_zombies,
  warn_timeout_seconds,
  kill_timeout_seconds,
  auto_enqueue,
  active
) VALUES (
  'digimaps_waitForExclusiveAccess',
  'digimaps',
  'parcel',
  '10006',
  '{"additionalExclusions": ["blackknight"]}',
  '0',
  '24', -- with its 1-hour timeout, this means it could wait for 1 full day before the whole task must retry
  'f',
  't',
  'f',
  NULL,
  '3600',
  't',
  't'
);

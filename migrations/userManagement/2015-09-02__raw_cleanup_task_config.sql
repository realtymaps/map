
DELETE FROM jq_task_config WHERE name = 'raw_cleanup';
DELETE FROM jq_task_config WHERE name = 'cleanup';
INSERT INTO jq_task_config (
  name,
  description,
  data,
  repeat_period_minutes,
  fail_retry_minutes,
  warn_timeout_minutes,
  kill_timeout_minutes,
  active
) VALUES (
  'cleanup',
  'Clean up old logs, temp data tables, etc',
  '{}',
  '1440',
  '60',
  '10',
  '15',
  TRUE
);


DELETE FROM jq_subtask_config WHERE task_name = 'raw_cleanup';
DELETE FROM jq_subtask_config WHERE task_name = 'cleanup';

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
  'cleanup_rawTables',
  'cleanup',
  'misc',
  '1',
  '30',
  '2',
  TRUE,
  TRUE,
  TRUE,
  300,
  600,
  TRUE
);

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
  'cleanup_subtaskErrors',
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

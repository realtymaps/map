ALTER TABLE jq_subtask_config ADD COLUMN auto_enqueue BOOLEAN NOT NULL DEFAULT TRUE;

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
  'normalizeData',
  'mls_swfl',
  'mls',
  '2',
  '0',
  TRUE,
  TRUE,
  TRUE,
  30,
  45,
  FALSE
);

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
  'markDeleted',
  'mls_swfl',
  'mls',
  '3',
  '0',
  TRUE,
  TRUE,
  TRUE,
  20,
  30,
  FALSE
);

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
  'finalizeData',
  'mls_swfl',
  'mls',
  '4',
  '0',
  TRUE,
  TRUE,
  TRUE,
  120,
  150,
  TRUE
);

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
  'removeExtraRows',
  'mls_swfl',
  'mls',
  '5',
  '0',
  TRUE,
  TRUE,
  TRUE,
  20,
  30,
  FALSE
);

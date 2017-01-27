UPDATE "jq_subtask_config"
SET step_num = step_num + 1
WHERE step_num > 5;

INSERT INTO "jq_subtask_config" (
  "name",
  "task_name",
  "queue_name",
  "step_num",
  "data",
  "retry_delay_seconds",
  "retry_max_count",
  "hard_fail_timeouts",
  "hard_fail_after_retries",
  "hard_fail_zombies",
  "warn_timeout_seconds",
  "kill_timeout_seconds",
  "auto_enqueue",
  "active"
) VALUES (
  '<default_mls_config>_clearPhotoRetries',
  '<default_mls_config>',
  'mls',
  10006,
  NULL,
  10,
  5,
  FALSE,
  TRUE,
  FALSE,
  30,
  60,
  TRUE,
  TRUE
);

INSERT INTO "jq_subtask_config" (
  "name",
  "task_name",
  "queue_name",
  "step_num",
  "data",
  "retry_delay_seconds",
  "retry_max_count",
  "hard_fail_timeouts",
  "hard_fail_after_retries",
  "hard_fail_zombies",
  "warn_timeout_seconds",
  "kill_timeout_seconds",
  "auto_enqueue",
  "active"
) VALUES (
  'swflmls_clearPhotoRetries',
  'swflmls',
  'mls',
  10006,
  NULL,
  10,
  5,
  FALSE,
  TRUE,
  FALSE,
  30,
  60,
  TRUE,
  TRUE
);

INSERT INTO "jq_subtask_config" (
  "name",
  "task_name",
  "queue_name",
  "step_num",
  "data",
  "retry_delay_seconds",
  "retry_max_count",
  "hard_fail_timeouts",
  "hard_fail_after_retries",
  "hard_fail_zombies",
  "warn_timeout_seconds",
  "kill_timeout_seconds",
  "auto_enqueue",
  "active"
) VALUES (
  'MRED_clearPhotoRetries',
  'MRED',
  'mls',
  10006,
  NULL,
  10,
  5,
  FALSE,
  TRUE,
  FALSE,
  30,
  60,
  TRUE,
  TRUE
);

INSERT INTO "jq_subtask_config" (
  "name",
  "task_name",
  "queue_name",
  "step_num",
  "data",
  "retry_delay_seconds",
  "retry_max_count",
  "hard_fail_timeouts",
  "hard_fail_after_retries",
  "hard_fail_zombies",
  "warn_timeout_seconds",
  "kill_timeout_seconds",
  "auto_enqueue",
  "active"
) VALUES (
  'GLVAR_clearPhotoRetries',
  'GLVAR',
  'mls',
  10006,
  NULL,
  10,
  5,
  FALSE,
  TRUE,
  FALSE,
  30,
  60,
  TRUE,
  TRUE
);


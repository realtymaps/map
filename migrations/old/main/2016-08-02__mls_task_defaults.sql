INSERT INTO "jq_task_config" (
  SELECT
    '<default_mls_config>' AS "name",
    "description",
    "data",
    "ignore_until",
    "repeat_period_minutes",
    "warn_timeout_minutes",
    "kill_timeout_minutes",
    FALSE AS "active",
    "fail_retry_minutes"
  FROM "jq_task_config"
  WHERE name = 'swflmls'
);

INSERT INTO "jq_subtask_config" (
  SELECT
    replace(name, 'swflmls', '<default_mls_config>') AS "name",
    '<default_mls_config>' AS "task_name",
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
  FROM "jq_subtask_config"
  WHERE task_name = 'swflmls'
);

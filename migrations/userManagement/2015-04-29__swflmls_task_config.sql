
INSERT INTO jq_queue_config (
  name,
  lock_id,
  processes_per_dyno,
  subtasks_per_process,
  priority_factor,
  active
) VALUES (
  'mls',
  x'202addb0'::INTEGER,
  '2',
  '4',
  '0.5',
  TRUE
);

INSERT INTO jq_task_config (
  name,
  description,
  data,
  repeat_period_minutes,
  warn_timeout_minutes,
  kill_timeout_minutes,
  active
) VALUES (
  'mls_swfl',
  'Refresh the SWFL MLS data every 15 minutes',
  '{ "url": "http://matrix.swflamls.com/rets/login.ashx", "login": "NAPMLSRealtyMapster", "password": "F8YItcWlSkzR9EOeHrnB3w==$$o9Z8OizE1BrlfQ==$" }',
  '15',
  '5',
  '6',
  FALSE
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
  kill_timeout_seconds
) VALUES (
  'loadDataRawMain',
  'mls_swfl',
  'mls',
  '1',
  '10',
  '10',
  FALSE,
  TRUE,
  TRUE,
  60,
  75
);


INSERT INTO jq_queue_config (
  name,
  lock_id,
  processes_per_dyno,
  subtasks_per_process,
  priority_factor,
  active
) VALUES (
  'parcel_update',
  x'b81fc714'::INTEGER,
  '1',
  '3',
  '0.10',
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
  'parcel_update',
  'Fetch new parcels save them to the parcels tables, sync mv_parcels, then sync cartodb.',
  '[]',
  '1440', -- 24 hr x 60 min
  '1',
  '2',
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
  'parcel_update_digimaps',
  'parcel_update',
  'parcel_update_digimaps',
  '1',
  '4',
  '4',
  FALSE,
  TRUE,
  TRUE,
  300,
  600
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
  'parcel_update_sync_mv_parcels',
  'parcel_update',
  'parcel_update_sync_mv_parcels',
  'parcel',
  '2',
  '4',
  '4',
  FALSE,
  TRUE,
  TRUE,
  300,
  600
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
  'parcel_update_sync_cartodb',
  'parcel_update',
  'parcel_update_sync_cartodb',
  'parcel',
  '3',
  '4',
  '4',
  FALSE,
  TRUE,
  TRUE,
  300,
  600
);

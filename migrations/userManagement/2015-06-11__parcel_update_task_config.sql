
DELETE from jq_subtask_config where name = 'digimaps';

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
  'digimaps_define_imports',
  'parcel_update',
  'parcel_update',
  '1',
  '4',
  '4',
  FALSE,
  TRUE,
  TRUE,
  300,
  600
);

INSERT INTO jq_subtask_config(
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
  'digimaps_save',
  'parcel_update',
  'parcel_update',
  '2',
  '4',
  '4',
  FALSE,
  TRUE,
  TRUE,
  300,
  600
);

UPDATE jq_subtask_config set "step_num"='3' where name = 'sync_mv_parcels';
UPDATE jq_subtask_config set "step_num"='4' where name = 'sync_cartodb';

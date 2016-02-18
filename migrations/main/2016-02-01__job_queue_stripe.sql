DELETE FROM jq_queue_config WHERE name = 'stripe';
INSERT INTO jq_queue_config VALUES (
  'stripe', --name
   548519642, --lock_id
   1, --processes_per_dyno
   5, --subtasks_per_process
   2, --priority_factor
   true); --active


  DELETE FROM jq_task_config WHERE name = 'stripe';
  INSERT INTO jq_task_config
  VALUES (
    'stripe', --name
    'Janitor task for stripe', --description
    '{}', --data
    NULL, --ignore_until
    30, --repeat_period_minutes
    5, --warn_timeout_minutes
    5, --kill_timeout_minutes
    true, --active
    5); --fail_retry_minutes


DELETE FROM jq_subtask_config WHERE task_name = 'stripe';

INSERT INTO jq_subtask_config
VALUES (
  'stripe_findStripeErrors', --name
  'stripe', --task_name
  'stripe', --queue_name
  1, --step_num
  'null', --data
  NULL, -- retry_delay_seconds
  5, -- retry_max_count
  true, -- hard_fail_timeouts
  true, -- hard_fail_after_retries
  true,  -- hard_fail_zombies
  NULL, -- warn_timeout_seconds
  NULL, --kill_timeout_seconds
  true); -- auto_enqueue


INSERT INTO jq_subtask_config
VALUES (
  'stripe_removeErroredCustomers', --name
  'stripe', --task_name
  'stripe', --queue_name
  2, --step_num
  'null', --data
  NULL, -- retry_delay_seconds
  5, -- retry_max_count
  true, -- hard_fail_timeouts
  true, -- hard_fail_after_retries
  true,  -- hard_fail_zombies
  NULL, -- warn_timeout_seconds
  NULL, --kill_timeout_seconds
  true); -- auto_enqueue

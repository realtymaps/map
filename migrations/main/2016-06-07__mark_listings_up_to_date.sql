UPDATE jq_subtask_config SET step_num = step_num + 1 WHERE queue_name = 'mls' AND step_num IN ('3', '4', '10005');

INSERT INTO jq_subtask_config (
  name, task_name, queue_name, step_num, data, retry_delay_seconds, retry_max_count, hard_fail_timeouts,
  hard_fail_after_retries, hard_fail_zombies, warn_timeout_seconds, kill_timeout_seconds, auto_enqueue, active)
VALUES ( 'MRED_markUpToDate', 'MRED', 'mls', '3', null, '30', '10', FALSE, TRUE, FALSE, '1000', '1200', FALSE, TRUE);

INSERT INTO jq_subtask_config (
  name, task_name, queue_name, step_num, data, retry_delay_seconds, retry_max_count, hard_fail_timeouts,
  hard_fail_after_retries, hard_fail_zombies, warn_timeout_seconds, kill_timeout_seconds, auto_enqueue, active)
VALUES ( 'swflmls_markUpToDate', 'swflmls', 'mls', '3', null, '30', '10', FALSE, TRUE, FALSE, '1000', '1200', FALSE, TRUE);

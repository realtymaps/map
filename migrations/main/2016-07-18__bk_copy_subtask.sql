-- We're inserting a new first step, so advance all stepnums by 1 for blackknight
UPDATE jq_subtask_config
SET step_num = step_num + 1
WHERE task_name = 'blackknight';

INSERT INTO jq_subtask_config (
  name, task_name, queue_name, step_num, data, retry_delay_seconds, retry_max_count, hard_fail_timeouts,
  hard_fail_after_retries, hard_fail_zombies, warn_timeout_seconds, kill_timeout_seconds, auto_enqueue, active)
VALUES ( 'blackknight_copyFtpDrop', 'blackknight', 'misc', '1', null, '30', '10', FALSE, TRUE, FALSE, '240', '300', TRUE, TRUE);

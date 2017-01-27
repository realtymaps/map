UPDATE jq_subtask_config
SET step_num = step_num + 1
WHERE task_name = 'blackknight' and step_num >= 10003;

-- fit the copydate subtask into the `10000` range, maintaining 'room' for the prior copy subtask's parallels
INSERT INTO jq_subtask_config (
  name, task_name, queue_name, step_num, data, retry_delay_seconds, retry_max_count, hard_fail_timeouts,
  hard_fail_after_retries, hard_fail_zombies, warn_timeout_seconds, kill_timeout_seconds, auto_enqueue, active)
VALUES ( 'blackknight_saveCopyDates', 'blackknight', 'misc', '10003', 'null', '30', '10', FALSE, TRUE, FALSE, '240', '300', FALSE, TRUE);

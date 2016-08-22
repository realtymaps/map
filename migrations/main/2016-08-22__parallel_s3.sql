-- step "4" is missing, so increment 2 and 3 to make room for new step 2
UPDATE jq_subtask_config
SET step_num = step_num + 1
WHERE task_name = 'blackknight' and step_num in (2,3);

-- add 10000 to the later subtasks to make "room" for concurrency of earlier subtasks
UPDATE jq_subtask_config
SET step_num = step_num + 10000
WHERE task_name = 'blackknight' and step_num > 1;

INSERT INTO jq_subtask_config (
  name, task_name, queue_name, step_num, data, retry_delay_seconds, retry_max_count, hard_fail_timeouts,
  hard_fail_after_retries, hard_fail_zombies, warn_timeout_seconds, kill_timeout_seconds, auto_enqueue, active)
VALUES ( 'blackknight_copyFile', 'blackknight', 'misc', '2', "null", '30', '10', FALSE, TRUE, FALSE, '240', '300', FALSE, TRUE);

-- rename corelogic queue to county
UPDATE jq_queue_config SET name = 'county' WHERE name = 'corelogic';
UPDATE jq_subtask_config SET queue_name = 'county' WHERE queue_name = 'corelogic';


INSERT INTO jq_subtask_config
(name, task_name, queue_name, step_num, data, retry_delay_seconds, retry_max_count, hard_fail_timeouts, hard_fail_after_retries, hard_fail_zombies, warn_timeout_seconds, kill_timeout_seconds, auto_enqueue)
VALUES ('blackknight_checkFtpDrop', 'corelogic', 'misc', 1, NULL, 30, 10, false, true, true, 240, 300, true);
INSERT INTO jq_subtask_config
  (name, task_name, queue_name, step_num, data, retry_delay_seconds, retry_max_count, hard_fail_timeouts, hard_fail_after_retries, hard_fail_zombies, warn_timeout_seconds, kill_timeout_seconds, auto_enqueue)
  VALUES ('blackknight_loadRawData', 'blackknight', 'county', 2, '{"dataType":"listing"}', 30, 10, false, true, true, 240, 300, false);
INSERT INTO jq_subtask_config
  (name, task_name, queue_name, step_num, data, retry_delay_seconds, retry_max_count, hard_fail_timeouts, hard_fail_after_retries, hard_fail_zombies, warn_timeout_seconds, kill_timeout_seconds, auto_enqueue)
  VALUES ('blackknight_deleteData', 'blackknight', 'county', 3, NULL, NULL, 0, true, true, true, 60, 75, false);
INSERT INTO jq_subtask_config
  (name, task_name, queue_name, step_num, data, retry_delay_seconds, retry_max_count, hard_fail_timeouts, hard_fail_after_retries, hard_fail_zombies, warn_timeout_seconds, kill_timeout_seconds, auto_enqueue)
  VALUES ('blackknight_normalizeData', 'blackknight', 'county', 4, NULL, NULL, 0, true, true, true, 240, 300, false);
INSERT INTO jq_subtask_config
  (name, task_name, queue_name, step_num, data, retry_delay_seconds, retry_max_count, hard_fail_timeouts, hard_fail_after_retries, hard_fail_zombies, warn_timeout_seconds, kill_timeout_seconds, auto_enqueue)
  VALUES ('blackknight_recordChangeCounts', 'blackknight', 'county', 5, NULL, NULL, 0, true, true, true, 60, 75, false);
INSERT INTO jq_subtask_config
  (name, task_name, queue_name, step_num, data, retry_delay_seconds, retry_max_count, hard_fail_timeouts, hard_fail_after_retries, hard_fail_zombies, warn_timeout_seconds, kill_timeout_seconds, auto_enqueue)
  VALUES ('blackknight_finalizeDataPrep', 'blackknight', 'county', 6, NULL, NULL, 0, true, true, true, 60, 75, false);
INSERT INTO jq_subtask_config
  (name, task_name, queue_name, step_num, data, retry_delay_seconds, retry_max_count, hard_fail_timeouts, hard_fail_after_retries, hard_fail_zombies, warn_timeout_seconds, kill_timeout_seconds, auto_enqueue)
  VALUES ('blackknight_finalizeData', 'blackknight', 'county', 7, NULL, NULL, 0, true, true, true, 240, 300, false);
INSERT INTO jq_subtask_config
  (name, task_name, queue_name, step_num, data, retry_delay_seconds, retry_max_count, hard_fail_timeouts, hard_fail_after_retries, hard_fail_zombies, warn_timeout_seconds, kill_timeout_seconds, auto_enqueue)
  VALUES ('blackknight_activateNewData', 'blackknight', 'county', 8, NULL, NULL, 0, true, true, true, 240, 300, false);
INSERT INTO jq_subtask_config
  (name, task_name, queue_name, step_num, data, retry_delay_seconds, retry_max_count, hard_fail_timeouts, hard_fail_after_retries, hard_fail_zombies, warn_timeout_seconds, kill_timeout_seconds, auto_enqueue)
  VALUES ('blackknight_saveProcessDates', 'blackknight', 'county', 9, NULL, NULL, 0, true, true, true, 15, 30, false);

INSERT INTO jq_task_config
  (name, description, data, ignore_until, repeat_period_minutes, warn_timeout_minutes, kill_timeout_minutes, active, fail_retry_minutes)
  VALUES ('blackknight', 'Check every day for new blackknight data files to process', '{}', NULL, 1440, 20, 25, false, 60);


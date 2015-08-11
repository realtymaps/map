
INSERT INTO jq_queue_config (
  name,
  lock_id,
  processes_per_dyno,
  subtasks_per_process,
  priority_factor,
  active
) VALUES (
  'misc',
  x'53ac75a1'::INTEGER,
  '2',
  '2',
  '0.5',
  TRUE
);

INSERT INTO jq_queue_config (
  name,
  lock_id,
  processes_per_dyno,
  subtasks_per_process,
  priority_factor,
  active
) VALUES (
  'corelogic',
  x'744ec762'::INTEGER,
  '10',
  '1',
  '0.5',
  TRUE
);

INSERT INTO jq_task_config (
  name,
  description,
  data,
  repeat_period_minutes,
  fail_retry_minutes,
  warn_timeout_minutes,
  kill_timeout_minutes,
  active
) VALUES (
  'corelogic',
  'Check every day for new corelogic data files to process',
  '{ "host": "ftp2.resftp.com", "user": "Realty_Mapster", "password": "8jB3806SWz0EPGD7q5p7eQ==$$e3slABJrzSyidfY=$" }',
  '1440',
  '60',
  '20',
  '25',
  FALSE
);

-- this will check the FTP drop for files that need to be processed
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
  kill_timeout_seconds,
  auto_enqueue
) VALUES (
  'corelogic_checkFtpDrop',
  'corelogic',
  'misc',
  '1',
  '30',
  '10',
  FALSE,
  TRUE,
  TRUE,
  240,
  300,
  TRUE
);

-- there will be 1 copy of this subtask for each file that needs to be downloaded into a raw table
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
  kill_timeout_seconds,
  auto_enqueue
) VALUES (
  'corelogic_loadRawData',
  'corelogic',
  'corelogic',
  '2',
  '30',
  '10',
  FALSE,
  TRUE,
  TRUE,
  240,
  300,
  FALSE
);

-- there will be 1 copy of this subtask for each file that needs to be downloaded into a raw table
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
  kill_timeout_seconds,
  auto_enqueue
) VALUES (
  'corelogic_normalizeData',
  'corelogic',
  'corelogic',
  '3',
  NULL,
  '0',
  TRUE,
  TRUE,
  TRUE,
  240,
  300,
  FALSE
);

-- there will be 1 copy of this subtask for every 500 rows (configured in
-- task.coreLogic.coffee) loaded by the tasks of the previous step
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
  kill_timeout_seconds,
  auto_enqueue
) VALUES (
  'corelogic_recordChangeCounts',
  'corelogic',
  'corelogic',
  '4',
  NULL,
  '0',
  TRUE,
  TRUE,
  TRUE,
  60,
  75,
  FALSE
);

-- this subtask enqueues dynamic subtasks for the next step
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
  kill_timeout_seconds,
  auto_enqueue
) VALUES (
  'corelogic_finalizeDataPrep',
  'corelogic',
  'corelogic',
  '5',
  NULL,
  '0',
  TRUE,
  TRUE,
  TRUE,
  60,
  75,
  FALSE
);

-- this subtask enqueues dynamic subtasks for the next step
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
  kill_timeout_seconds,
  auto_enqueue
) VALUES (
  'corelogic_finalizeData',
  'corelogic',
  'corelogic',
  '5',
  NULL,
  '0',
  TRUE,
  TRUE,
  TRUE,
  60,
  75,
  FALSE
);

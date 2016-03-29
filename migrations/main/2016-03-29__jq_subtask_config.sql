ALTER TABLE jq_subtask_config ADD PRIMARY KEY (name) NOT DEFERRABLE INITIALLY IMMEDIATE;


insert into jq_subtask_config
(
  hard_fail_after_retries,
  retry_max_count,
  name,
  auto_enqueue,
  step_num,
  queue_name,
  hard_fail_zombies,
  task_name,
  data,
  kill_timeout_seconds,
  warn_timeout_seconds,
  retry_delay_seconds,
  hard_fail_timeouts
)
values
( 't', '0', 'swflmls_storePhotosPrep',  'f', '7', 'mls',  't', 'swflmls', null, '750', '600', null, 't'),
( 't', '0', 'swflmls_storePhotos',      'f', '8', 'mls',  't', 'swflmls', null, '45',  '30',  '30', 't'),
( 't', '0', 'MRED_storePhotosPrep',     'f', '7', 'mls',  't', 'MRED',    null, '750', '600', null, 't'),
( 't', '0', 'MRED_storePhotos',         'f', '8', 'mls',  't', 'MRED',    null, '45',  '30',  '30', 't'),
( 't', '0', 'GLVAR_storePhotosPrep',    'f', '7', 'mls',  't', 'GLVAR',   null, '750', '600', null, 't'),
( 't', '0', 'GLVAR_storePhotos',        'f', '8', 'mls',  't', 'GLVAR',   null, '45',  '30',  '30', 't'),

( 't', '2', 'cleanup_deletePhotosPrep', 't', '1', 'misc', 't', 'cleanup', null, '600', '300', '30', 't'),
( 't', '0', 'cleanup_deletePhotos',     'f', '2', 'misc', 't', 'cleanup', null, '300', '240', null, 't');

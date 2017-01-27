insert into jq_task_config (
  name,
  description,
  data,
  repeat_period_minutes,
  warn_timeout_minutes,
  active,
  fail_retry_minutes,
  blocked_by_tasks,
  blocked_by_locks)
values (
  'geocode_fipsCodes',
  'Geocode lookupFipsCodes.',
  '{}',
  '500',
  '1',
  'f',
  '1',
  '[]',
  '[]');


insert into jq_subtask_config (
  name, task_name, queue_name, step_num,
  data, retry_max_count, auto_enqueue, active,
  retry_delay_minutes, kill_timeout_minutes, warn_timeout_minutes)
values (
  'geocode_fipsCodes_loadRawData', 'geocode_fipsCodes', 'misc', '1',
  null, '4', 't', 't',
  '1', null, '30');

insert into jq_subtask_config (
  name, task_name, queue_name, step_num,
  data, retry_max_count, auto_enqueue, active,
  retry_delay_minutes, kill_timeout_minutes, warn_timeout_minutes)
values (
  'geocode_fipsCodes_normalize', 'geocode_fipsCodes', 'misc', '2',
  null, '4', 'f', 't',
  '1', null, '5');

insert into jq_subtask_config (
  name, task_name, queue_name, step_num,
  data, retry_max_count, auto_enqueue, active,
  retry_delay_minutes, kill_timeout_minutes, warn_timeout_minutes)
values (
  'geocode_fipsCodes_finalize', 'geocode_fipsCodes', 'misc', '3',
  null, '4', 'f', 't',
  '1', null, '5');

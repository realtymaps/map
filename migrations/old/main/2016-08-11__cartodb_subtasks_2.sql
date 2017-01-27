insert into jq_task_config (
  name,
  description,
  data,
  ignore_until,
  repeat_period_minutes,
  warn_timeout_minutes,
  kill_timeout_minutes,
  active,
  fail_retry_minutes)
  values ( 'cartodb', 'Process Cartodb aintenance and updates.', '{}', null, '20', '1', '2', 't', '1');


update jq_subtask_config
  set task_name = 'cartodb'
  where name = 'cartodb_wake';

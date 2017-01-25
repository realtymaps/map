insert into jq_subtask_config
  ( name, task_name, queue_name,
    step_num, data, retry_max_count,
    auto_enqueue, active, retry_delay_minutes,
    kill_timeout_minutes, warn_timeout_minutes)
  values
  ( 'events_weeklyEvents', 'events', 'events',
    '3', null, '10',
    't', 't', '1',
    null, '10'
  ),
  ( 'events_monthlyEvents', 'events', 'events',
    '4', null, '10',
    't', 't', '1',
    null, '30'
  ),
  ( 'events_weeklyNotifications', 'events', 'events',
    '5007', null, '10',
    'f', 't', '1',
    null, '20'
  ),
  ('events_monthlyNotifications', 'events', 'events',
    '5007', null, '10',
    'f', 't', '1',
    null, '40'
  );

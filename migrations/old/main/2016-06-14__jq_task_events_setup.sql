insert into jq_queue_config (
  lock_id,
  name,
  processes_per_dyno,
  subtasks_per_process,
  priority_factor,
  active)
values ( 998441378, 'events', '5', '3', '3', 't');


insert into jq_task_config (
  name, description, data,
  ignore_until, repeat_period_minutes, warn_timeout_minutes,
  kill_timeout_minutes, active, fail_retry_minutes
)
values
(
  'eventsDequeue', 'Proccess Events and dequeue them.', '{}',
  null, '4', '2',
  '3', 't','1'
),
(
  'notifications', 'Proccess the user_notification_queue', '{}',
  null, '5', '3', -- is this timeout too aggressive for daily?
  '4', 't','1'
);


insert into jq_subtask_config (
  name, task_name, queue_name,
  step_num, data, retry_delay_seconds, retry_max_count,
  hard_fail_timeouts, hard_fail_after_retries, hard_fail_zombies,
  warn_timeout_seconds, kill_timeout_seconds, auto_enqueue, active
)
  values
  (
    'eventsDequeue_deleteEventsQueue', 'eventsDequeue', 'events',
    '1', null, '15', '10',
    'f', 't', 'f',
    '60', '90', 't', 't'
  ),
  (
    'eventsDequeue_daily', 'eventsDequeue', 'events',
    '2', null, '15', '10',
    'f', 't', 'f',
    '600', '700', 't', 't'
  ),
  (
    'eventsDequeue_onDemand', 'eventsDequeue', 'events',
    '2', null, '15', '10',
    'f', 't', 'f',
    '60', '90', 't', 't'
  ),
  (
    'eventsDequeue_compactEvents', 'eventsDequeue', 'events',
    '5003', null, '15', '10',
    'f', 't', 'f',
    '60', '90', 'f', 't'
  ),
  (
    'eventsDequeue_processEvent', 'eventsDequeue', 'events',
    '5004', null, '15', '10',
    'f', 't', 'f',
    '45', '60', 'f', 't'
  ),
-- @@@@@@@@@@@@@@@@@@@@@ NOTIFICATIONS SUBTASKS @@@@@@@@@@@@@@@@@@@@@@@@@
  (
    'notifications_deleteNotificationsQueue', 'notifications', 'events',
    '1', null, '15', '10',
    'f', 't', 'f',
    '60', '90', 't', 't'
  ),
  (
    'notifications_daily', 'notifications', 'events',
    '2', null, '15', '10',
    'f', 't', 'f',
    '60', '90', 't', 't'
  ),
  (
    'notifications_onDemand', 'notifications', 'events',
    '2', null, '15', '10',
    'f', 't', 'f',
    '600', '700', 't', 't'
  ),
  (
    'notifications_sendNotifications', 'notifications', 'events',
    '5003', null, '15', '10',
    'f', 't', 'f',
    '200', '300', 'f', 't'
  );

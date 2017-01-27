delete from jq_task_config
where name in ('eventsDequeue', 'notifications');

insert into jq_task_config (
  name, description, data,
  ignore_until, repeat_period_minutes, warn_timeout_minutes,
  kill_timeout_minutes, active, fail_retry_minutes
)
values
(
  'events', 'Proccess events (digest/compaction), publish notifications, and distribute notifications.', '{}',
  null, '4', '2',
  '3', 't','1'
);

delete from jq_subtask_config
where name like '%eventsDequeue%' or name like '%notifications%';

insert into jq_subtask_config (
  name, task_name, queue_name,
  step_num, data, retry_delay_seconds, retry_max_count,
  hard_fail_timeouts, hard_fail_after_retries, hard_fail_zombies,
  warn_timeout_seconds, kill_timeout_seconds, auto_enqueue, active
)
  values
  -- begin auto_enqeue
  -- only two tasks below are auto_enqueue as everything else is dependent to come after
  (
    'dailyEvents', 'events', 'events',
    '1', null, '15', '10',
    'f', 't', 'f',
    '600', '700', 't', 't'
  ),
  (
    'onDemandEvents', 'events', 'events',
    '1', null, '15', '10',
    'f', 't', 'f',
    '60', '90', 't', 't'
  ),
  -- end auto_enqueue
  (
    'compactEvents', 'events', 'events',
    '5002', null, '15', '10',
    'f', 't', 'f',
    '60', '90', 'f', 't'
  ),
  (
    'processEvent', 'events', 'events',
    '5003', null, '15', '10',
    'f', 't', 'f',
    '45', '60', 'f', 't'
  ),
-- @@@@@@@@@@@ NOTIFICATIONS SUBTASKS @@@@@@@@@@@
  (
    'dailyNotifications', 'events', 'events',
    '5004', null, '15', '10',
    'f', 't', 'f',
    '60', '90', 'f', 't'
  ),
  (
    'onDemandNotifications', 'events', 'events',
    '5004', null, '15', '10',
    'f', 't', 'f',
    '600', '700', 'f', 't'
  ),
  (
    'sendNotifications', 'events', 'events',
    '10005', null, '15', '10',
    'f', 't', 'f',
    '200', '300', 'f', 't'
  );

alter table user_notification_config drop column max_attempts;


insert into jq_subtask_config (
  name, task_name, queue_name,
  step_num, data, retry_delay_seconds, retry_max_count,
  hard_fail_timeouts, hard_fail_after_retries, hard_fail_zombies,
  warn_timeout_seconds, kill_timeout_seconds, auto_enqueue, active
)
values
(
  'events_cleanupNotifications', 'events', 'events',
  '10008', null, '15', '10',
  'f', 't', 'f',
  '600', '700', 'f', 't'
);

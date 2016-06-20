
insert into jq_subtask_config (
  name, task_name, queue_name,
  step_num, data, retry_delay_seconds, retry_max_count,
  hard_fail_timeouts, hard_fail_after_retries, hard_fail_zombies,
  warn_timeout_seconds, kill_timeout_seconds, auto_enqueue, active
)
select
  'events_doneEvents', 'events', 'events',
  step_num, null, '15', '10',
  'f', 't', 'f',
  '600', '700', 'f', 't'
  from jq_subtask_config
  where queue_name = 'events' and name = 'events_onDemandNotifications';

update jq_subtask_config
  set step_num = step_num + 1
where queue_name = 'events' and name ilike '%notifications%';

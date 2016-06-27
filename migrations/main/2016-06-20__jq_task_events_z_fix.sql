update jq_subtask_config
  set name = 'events_' || name
where queue_name = 'events';

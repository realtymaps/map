update jq_subtask_config
  set step_num = step_num + 1
where queue_name = 'events' and name != 'events_onDemandEvents';

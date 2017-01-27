update jq_subtask_config
  set task_name = 'cleanup'
  where name = 'cartodb_wake';

delete from jq_task_config where name = 'cartodb';

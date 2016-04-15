update jq_queue_config
  set name='parcel'
where name = 'parcel_update';

update jq_task_config
  set name='digimaps'
where name = 'parcel_update';

delete from jq_subtask_config
where queue_name like '%parcel%';

insert into jq_subtask_config
  (
    name,
    task_name,
    queue_name,
    step_num,
    data,
    retry_delay_seconds,
    retry_max_count,
    hard_fail_timeouts,
    hard_fail_after_retries,
    hard_fail_zombies,
    warn_timeout_seconds,
    kill_timeout_seconds,
    auto_enqueue,
    active)
values
( 'loadRawDataPrep', 'digimaps', 'parcel', '1', null, '30', '30', 'f', 't', 't', '450', '600', 't', 't'),
( 'loadRawData', 'digimaps', 'parcel', '2', null, '30', '30', 'f', 't', 't', '450', '600', 'f', 't');

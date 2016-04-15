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
( 'normalizeData', 'digimaps', 'parcel', '3', null, '30', '10', 'f', 't', 't', '200', '300', 'f', 't');

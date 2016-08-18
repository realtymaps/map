insert into jq_task_config (
	name,
  description,
  data,
  repeat_period_minutes,
  warn_timeout_minutes,
  kill_timeout_minutes
)
values (
	'swflmls_photos',
  'Load SWFL MLS photos',
  '{}',
  60,
  12,
  14
);

insert into jq_subtask_config (
	name,
	task_name,
	queue_name,
	step_num,
	retry_delay_seconds,
	hard_fail_timeouts,
	hard_fail_after_retries,
	hard_fail_zombies,
	retry_max_count,
	warn_timeout_seconds,
	kill_timeout_seconds,
	auto_enqueue
)
(
	select
		replace(name, 'Photos', ''),
		name || '_photos',
		queue_name,
		step_num,
		retry_delay_seconds,
		hard_fail_timeouts,
		hard_fail_after_retries,
		hard_fail_zombies,
		retry_max_count,
		warn_timeout_seconds,
		kill_timeout_seconds,
		auto_enqueue
	from jq_subtask_config where name like '%storePhotos%'
);

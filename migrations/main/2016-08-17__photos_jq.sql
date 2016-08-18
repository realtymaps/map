insert into jq_task_config (
	name,
  description,
  data,
  repeat_period_minutes,
  warn_timeout_minutes,
  kill_timeout_minutes
)
values (
	'<default_mls_photos_config>',
  'Load MLS photos',
  '{}',
  60,
  12,
  14
),
(
	'swflmls_photos',
  'Load MLS photos',
  '{}',
  60,
  12,
  14
),
(
	'MRED_photos',
  'Load MLS photos',
  '{}',
  60,
  12,
  14
),
(
	'GLVAR_photos',
  'Load MLS photos',
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
	auto_enqueue,
	active
)
(
	select
		replace(replace(replace(name, 'Photos', ''), 'Photo', ''), 'default_mls_config', 'default_mls_photos_config'),
		replace(replace(task_name || '_photos', '>_photos', '>'), 'default_mls_config', 'default_mls_photos_config'),
		queue_name,
		step_num,
		retry_delay_seconds,
		hard_fail_timeouts,
		hard_fail_after_retries,
		hard_fail_zombies,
		retry_max_count,
		warn_timeout_seconds,
		kill_timeout_seconds,
		auto_enqueue,
		active
	from jq_subtask_config where name like '%Photo%' and queue_name = 'mls'
);

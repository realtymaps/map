DELETE FROM jq_subtask_config WHERE name = 'digimaps_releaseExclusiveAccess';
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
values
(
	'digimaps_releaseExclusiveAccess',
	'digimaps',
	'parcel',
	10010,
	10,
	false,
	true,
	false,
	5,
	30,
	60,
	true,
	true
);

ALTER TABLE jq_task_config
ADD COLUMN blocked_by_tasks JSONB NOT NULL DEFAULT '[]'::JSONB,
ADD COLUMN blocked_by_locks JSONB NOT NULL DEFAULT '[]'::JSONB;


UPDATE jq_task_config
SET data = '{}'::JSON;


UPDATE jq_task_config
SET blocked_by_locks = '["digimapsExclusiveAccess"]'::JSONB
WHERE name IN ('blackknight', 'swflmls', 'GLVAR', 'MRED', '<default_mls_config>');

UPDATE jq_task_config
SET blocked_by_tasks = ('["'||name||'_photos"]')::JSONB
WHERE name IN ('swflmls', 'GLVAR', 'MRED', '<default_mls_config>');

UPDATE jq_task_config
SET blocked_by_tasks = ('["'||replace(name,'_photos','')||'"]')::JSONB
WHERE name IN ('swflmls_photos', 'GLVAR_photos', 'MRED_photos', '<default_mls_config>_photos');

UPDATE jq_subtask_config
SET data = '{}'::JSON
WHERE name = 'digimaps_waitForExclusiveAccess';

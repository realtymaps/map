UPDATE jq_subtask_config
SET step_num = step_num + 1
WHERE
  step_num >= 30011
  AND task_name = 'blackknight';

DELETE FROM jq_subtask_config WHERE name = 'blackknight_waitForExclusiveAccess';
INSERT INTO jq_subtask_config (
	name,
	task_name,
	queue_name,
	step_num,
	retry_delay_minutes,
	retry_max_count,
	warn_timeout_minutes,
	kill_timeout_minutes,
	auto_enqueue,
	active
)
VALUES
(
	'blackknight_waitForExclusiveAccess',
	'blackknight',
	'county',
	30011,
	1,
	1000,
	1,
	NULL,
	FALSE,
	TRUE
);

UPDATE jq_subtask_config
SET name = 'blackknight_cleanup'
WHERE name = 'blackknight_updateProcessInfo';


UPDATE jq_task_config
SET blocked_by_locks = '["digimapsExclusiveAccess","blackknightExclusiveAccess"]'::JSONB
WHERE name IN ('RAPB', 'swflmls', 'GLVAR', 'MRED', '<default_mls_config>');

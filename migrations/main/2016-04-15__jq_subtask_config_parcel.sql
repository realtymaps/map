UPDATE jq_subtask_config
SET name='digimaps_'||t2.name
FROM jq_subtask_config t2
where jq_subtask_config.name=t2.name AND
t2.queue_name = 'parcel' AND t2.task_name = 'digimaps';

insert into jq_subtask_config (
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
	active
)
values
	( 'digimaps_recordChangeCounts', 'digimaps', 'parcel', '10004',
		null, null, '0', 't', 't', 't', '30', '45', 'f', 't'),

	( 'digimaps_finalizeDataPrep', 'digimaps', 'parcel', '10005',
		null, null, '0', 't', 't', 't', '30', '45', 'f', 't'),

	( 'digimaps_finalizeData', 'digimaps', 'parcel', '10006',
		null, null, '0', 't', 't', 't', '600', '750', 'f', 't'),

	( 'digimaps_activateNewData', 'digimaps', 'parcel', '10007',
		null, null, '0', 't', 't', 't', '240', '300', 'f', 't');

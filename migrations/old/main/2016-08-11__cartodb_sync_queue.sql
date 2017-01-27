CREATE TABLE cartodb_sync_queue (
  id serial,
  fips_code text,
  batch_id text NOT NULL,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);


INSERT INTO jq_subtask_config(
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
VALUES
	(
		'cartodb_syncPrep',
		'cartodb',
		'misc',
		'1',
		NULL,
		'4',
		'4',
		'f',
		't',
		'f',
		'60',
		'75',
		't',
		't'
	);

INSERT INTO jq_subtask_config(
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
VALUES
	(
		'cartodb_sync',
		'cartodb',
		'misc',
		'2',
		NULL,
		'4',
		'4',
		'f',
		't',
		'f',
		'60',
		'75',
		'f',
		't'
	);

INSERT INTO jq_subtask_config(
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
VALUES
	(
		'cartodb_syncDone',
		'cartodb',
		'misc',
		'3',
		NULL,
		'4',
		'4',
		'f',
		't',
		'f',
		'60',
		'75',
		'f',
		't'
	);

UPDATE jq_subtask_config SET name = 'parcelUpdate_' || name, task_name = 'parcelUpdate', queue_name = 'parcelUpdate' WHERE task_name = 'parcel_update';
UPDATE jq_task_config SET name = 'parcelUpdate' WHERE name = 'parcel_update';
UPDATE jq_queue_config SET name = 'parcelUpdate' WHERE name = 'parcel_update';

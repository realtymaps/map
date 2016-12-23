UPDATE jq_subtask_config
SET step_num = '1'
WHERE name LIKE '%_photo_storePrep';

UPDATE jq_subtask_config
SET step_num = '2'
WHERE name LIKE '%_photo_store';

UPDATE jq_subtask_config
SET step_num = '1000003'
WHERE name LIKE '%_photo_setLastUpdateTimestamp';

UPDATE jq_subtask_config
SET step_num = '1000004'
WHERE name LIKE '%_photo_clearRetries';

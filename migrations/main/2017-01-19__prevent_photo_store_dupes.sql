UPDATE jq_subtask_config
SET retry_max_count = 0
WHERE name LIKE '%_photo_storePrep';

UPDATE config_keystore
SET value = '1474416000000'  -- beginning of the day on Sept 21, 2016
WHERE
  key = 'swflmls_photos'
  AND namespace = 'data update timestamps';


UPDATE jq_subtask_config
SET auto_enqueue = TRUE
WHERE name = 'swflmls_photos_setLastUpdateTimestamp';

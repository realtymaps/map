
DELETE FROM config_keystore
WHERE
  namespace LIKE 'data % timestamps'
  AND (
    key LIKE '%_photo'
    --OR key LIKE '%_listing'
    --OR key LIKE '%_agent'
  );

TRUNCATE TABLE retry_photos;


UPDATE jq_subtask_config
SET
  kill_timeout_minutes = 30,
  warn_timeout_minutes = 20
WHERE name LIKE '%_store_photo';

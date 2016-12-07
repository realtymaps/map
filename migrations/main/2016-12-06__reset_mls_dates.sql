
DELETE FROM config_keystore
WHERE
  namespace LIKE 'data % timestamps'
  AND (
    key LIKE '%_photo'
    OR key LIKE '%_listing'
    OR key LIKE '%_agent'
  );

TRUNCATE TABLE retry_photos;

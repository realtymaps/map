
DELETE FROM config_keystore
WHERE
  namespace LIKE 'data % timestamps'
  AND key = '%_photo';

TRUNCATE TABLE retry_photos;

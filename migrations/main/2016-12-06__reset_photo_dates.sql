
DELETE FROM config_keystore
WHERE
  namespace LIKE 'data % timestamps'
  AND key = '%_photo';

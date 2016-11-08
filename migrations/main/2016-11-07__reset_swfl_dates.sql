
DELETE FROM config_keystore
WHERE
  namespace = 'data refresh timestamps'
  AND key = 'swflmls';
DELETE FROM config_keystore
WHERE
  namespace = 'data update timestamps'
  AND key = 'swflmls';

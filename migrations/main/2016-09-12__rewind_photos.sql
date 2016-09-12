-- rewind photos
DELETE FROM config_keystore
WHERE
  namespace = 'data update timestamps' AND
  key = 'swflmls_photos';

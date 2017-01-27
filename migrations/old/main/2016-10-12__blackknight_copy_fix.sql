UPDATE config_keystore
SET
  value = '"20160916"'::JSON
WHERE
  key = 'last completed date'
  AND namespace = 'blackknight copy info';

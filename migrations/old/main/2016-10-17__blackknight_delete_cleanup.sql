DELETE FROM config_keystore
WHERE
  namespace = 'paginateNumRows'
  AND key LIKE 'delete rows count: %';

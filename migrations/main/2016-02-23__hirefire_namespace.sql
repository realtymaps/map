UPDATE config_keystore
SET
  "namespace" = 'hirefire',
  "key" = 'last run timestamp'
WHERE key = 'hirefire run timestamp';

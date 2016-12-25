
DELETE FROM config_keystore
WHERE
  namespace LIKE 'data % timestamps'
  AND (
    key LIKE '%_listing'
    OR key LIKE '%_agent'
  );

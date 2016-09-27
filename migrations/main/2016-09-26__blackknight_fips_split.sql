UPDATE config_keystore
SET
  key = 'dates queued',
  namespace = 'blackknight process info'
WHERE
  key = 'Update'
  AND namespace = 'blackknight process dates';

DELETE FROM config_keystore
WHERE
  key = 'Refresh'
  AND namespace = 'blackknight process dates';


UPDATE config_keystore
SET
  key = 'last completed date',
  namespace = 'blackknight copy info'
WHERE
  key = 'Update'
  AND namespace = 'blackknight copy dates';

DELETE FROM config_keystore
WHERE
  key = 'Refresh'
  AND namespace = 'blackknight copy dates';


UPDATE config_keystore
SET
  key = 'last completed date'
WHERE
  key = 'last process date'
  AND namespace = 'digimaps process info';

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


UPDATE jq_subtask_config
SET name = 'blackknight_saveCopyDate'
WHERE name = 'blackknight_saveCopyDates';

UPDATE jq_subtask_config
SET name = 'blackknight_updateProcessInfo'
WHERE name = 'blackknight_saveProcessDates';

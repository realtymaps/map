UPDATE jq_subtask_config
SET name = 'blackknight_copyFtpDrop'
WHERE name = 'blackknight_checkProcessQueue';

UPDATE jq_subtask_config
SET name = 'blackknight_checkProcessQueue'
WHERE name = 'blackknight_checkFtpDrop';

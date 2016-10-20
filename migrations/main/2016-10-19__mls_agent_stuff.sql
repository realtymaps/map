UPDATE jq_subtask_config
SET data = NULL
WHERE
  queue_name = 'mls'
  AND name LIKE '%_loadRawData';


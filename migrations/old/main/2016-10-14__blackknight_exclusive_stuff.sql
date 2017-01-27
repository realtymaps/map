UPDATE jq_subtask_config
SET step_num = 30010
WHERE
  name = 'blackknight_waitForExclusiveAccess';

UPDATE jq_subtask_config
SET step_num = 30011
WHERE
  name = 'blackknight_finalizeData';

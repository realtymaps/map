-- this will fix it for the future
UPDATE jq_subtask_config
SET step_num = step_num + 9999
WHERE step_num > 20008;


-- this hotpatches the current task
UPDATE jq_current_subtasks
SET step_num = 20008
WHERE
  name = 'blackknight_recordChangeCounts'
  AND status = 'queued'
  AND step_num IN ('20012', '20013');

UPDATE jq_current_subtasks
SET step_num = 20009
WHERE
  name = 'blackknight_recordChangeCounts'
  AND status = 'queued'
  AND step_num IN ('20014', '20015', '20016');

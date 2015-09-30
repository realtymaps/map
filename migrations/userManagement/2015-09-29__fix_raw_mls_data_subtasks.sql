UPDATE jq_subtask_config
  SET data = '{"dataType":"listing"}'
  WHERE name ~ '\w+_loadRawData';

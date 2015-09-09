UPDATE jq_subtask_config
  SET name = replace(name, '_loadDataRawMain', '_loadRawData');

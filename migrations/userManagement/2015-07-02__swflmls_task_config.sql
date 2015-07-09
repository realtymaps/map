UPDATE jq_subtask_config
  SET kill_timeout_seconds = '750', warn_timeout_seconds = '600'
  WHERE name = 'swflmls_loadDataRawMain';

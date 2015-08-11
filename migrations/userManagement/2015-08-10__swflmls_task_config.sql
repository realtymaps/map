UPDATE jq_subtask_config
  SET auto_enqueue = FALSE
  WHERE name = 'swflmls_finalizeDataPrep';

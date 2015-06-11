UPDATE jq_subtask_config
  SET name = 'swflmls_' || name
  WHERE task_name = 'swflmls_';

CREATE UNIQUE INDEX ON jq_subtask_config (name);

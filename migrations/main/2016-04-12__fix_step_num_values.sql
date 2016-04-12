-- step_num values can't exceed 99999 without further code changes
UPDATE jq_subtask_config SET step_num = step_num - 1000000 + 10000 WHERE step_num >= 1000000;

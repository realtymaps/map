-- set this for all subtasks.  There's nothing that needs those to be TRUE right now.
UPDATE jq_subtask_config SET hard_fail_timeouts = FALSE, hard_fail_zombies = FALSE;

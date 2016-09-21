-- change all subtask times to use minutes instead of seconds
-- implicitly set the kill timeout to NULL in config, because it's really not needed 99% of the time any more (we can
--     always set a kill timeout value if there legitimately is a subtask that still needs it)
-- remove the 3x hard_fail_* settings, since I no longer see a reason we would ever need that to be configurable

ALTER TABLE jq_subtask_config
  ADD COLUMN retry_delay_minutes INTEGER,
  ADD COLUMN kill_timeout_minutes INTEGER,
  ADD COLUMN warn_timeout_minutes INTEGER;
UPDATE jq_subtask_config SET
  warn_timeout_minutes = CEILING(warn_timeout_seconds::NUMERIC/60)::INTEGER,
  retry_delay_minutes = CEILING(retry_delay_seconds::NUMERIC/60)::INTEGER;
ALTER TABLE jq_subtask_config
  DROP COLUMN hard_fail_timeouts,
  DROP COLUMN hard_fail_after_retries,
  DROP COLUMN hard_fail_zombies,
  DROP COLUMN warn_timeout_seconds,
  DROP COLUMN kill_timeout_seconds,
  DROP COLUMN retry_delay_seconds;

ALTER TABLE jq_current_subtasks
  ADD COLUMN retry_delay_minutes INTEGER,
  ADD COLUMN kill_timeout_minutes INTEGER,
  ADD COLUMN warn_timeout_minutes INTEGER;
UPDATE jq_current_subtasks SET
  kill_timeout_minutes = CEILING(kill_timeout_seconds::NUMERIC/60)::INTEGER,
  warn_timeout_minutes = CEILING(warn_timeout_seconds::NUMERIC/60)::INTEGER,
  retry_delay_minutes = CEILING(retry_delay_seconds::NUMERIC/60)::INTEGER;
ALTER TABLE jq_current_subtasks
  DROP COLUMN hard_fail_timeouts,
  DROP COLUMN hard_fail_after_retries,
  DROP COLUMN hard_fail_zombies,
  DROP COLUMN warn_timeout_seconds,
  DROP COLUMN kill_timeout_seconds,
  DROP COLUMN retry_delay_seconds;

ALTER TABLE jq_subtask_error_history
  ADD COLUMN retry_delay_minutes INTEGER,
  ADD COLUMN kill_timeout_minutes INTEGER,
  ADD COLUMN warn_timeout_minutes INTEGER;
UPDATE jq_subtask_error_history SET
  kill_timeout_minutes = CEILING(kill_timeout_seconds::NUMERIC/60)::INTEGER,
  warn_timeout_minutes = CEILING(warn_timeout_seconds::NUMERIC/60)::INTEGER,
  retry_delay_minutes = CEILING(retry_delay_seconds::NUMERIC/60)::INTEGER;
ALTER TABLE jq_subtask_error_history
  DROP COLUMN hard_fail_timeouts,
  DROP COLUMN hard_fail_after_retries,
  DROP COLUMN hard_fail_zombies,
  DROP COLUMN warn_timeout_seconds,
  DROP COLUMN kill_timeout_seconds,
  DROP COLUMN retry_delay_seconds;


-- a couple stored procedures that have been replaced by knex code
DROP FUNCTION IF EXISTS jq_update_task_counts();
DROP FUNCTION IF EXISTS jq_get_next_subtask(TEXT);


-- just like for subtasks, set the kill timeout to NULL, because it's really not needed 99% of the time (we can
--     always set a kill timeout value if there legitimately is a task that still needs it)
UPDATE jq_task_config
SET kill_timeout_minutes = NULL;

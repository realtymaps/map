-- this function should ideally be run in a transaction by itself, or else in auto-commit mode,
-- because the lock auto-unlocks by itself at the end of the transaction
CREATE OR REPLACE FUNCTION jq_get_next_subtask(source_queue_name TEXT) RETURNS jq_current_subtasks AS
  $$
  DECLARE
    queue_lock_id INTEGER;
    selected_subtask INTEGER;
    subtask_details jq_current_subtasks;
  BEGIN
    SELECT lock_id FROM jq_queue_config WHERE name = source_queue_name INTO queue_lock_id;

    PERFORM pg_advisory_xact_lock(jq_lock_key(), queue_lock_id);        -- get a lock on the queue...

    SELECT id
    FROM (                                                              -- and get the id...
      SELECT MIN(id) AS id                                              -- from the earliest-enqueued subtask...
      FROM jq_current_subtasks
      WHERE
        queue_name = source_queue_name AND                              -- that's in the queue with this lock... 
        status = 'queued' AND
        COALESCE(ignore_until, '1970-01-01'::TIMESTAMP) <= NOW() AND
        task_step IN (
          SELECT task_name || '_' ||  COALESCE(MIN(step_num)::TEXT, 'FINAL')    -- from the earliest step in each task...
          FROM (
            SELECT
              task_name,
              step_num
            FROM jq_current_subtasks
            WHERE queue_name = source_queue_name
            GROUP BY
              task_name,
              step_num
            HAVING                                                      -- that isn't yet acceptably finished...
              COUNT(
                status IN ('queued', 'preparing', 'running', 'hard fail', 'infrastructure fail') OR
                (status = 'timeout' AND hard_fail_timeouts = TRUE) OR
                (status = 'zombie' AND hard_fail_zombies = TRUE) OR
                NULL
              ) > 0
          ) AS task_steps
          GROUP BY task_name
        )
    ) AS selected_subtask_id
    INTO selected_subtask;

    UPDATE jq_current_subtasks                                          -- then mark the row we're grabbing...
    SET status = 'preparing'
    WHERE id = selected_subtask
    RETURNING *
    INTO subtask_details;                                               -- and return the data from that row

    RETURN subtask_details;
  END;
  $$
LANGUAGE plpgsql;

ALTER table jq_current_subtasks add column preparing_started TIMESTAMP;
ALTER table jq_subtask_error_history add column preparing_started TIMESTAMP;

CREATE OR REPLACE FUNCTION jq_get_next_subtask(source_queue_name text) RETURNS jq_current_subtasks
LANGUAGE plpgsql
AS $$
  DECLARE
    selected_subtask INTEGER;
    subtask_details jq_current_subtasks;
  BEGIN
    SELECT id                                                           -- get the id...
    FROM (
      SELECT MIN(id) AS id                                              -- from the earliest-enqueued subtask...
      FROM jq_current_subtasks
      WHERE
        queue_name = source_queue_name AND                              -- that's in the queue with this lock...
        status = 'queued' AND
        COALESCE(ignore_until, '1970-01-01'::TIMESTAMP) <= NOW() AND
        task_step IN (
          SELECT task_name || '_' ||  LPAD(COALESCE(MIN(step_num)::TEXT, 'FINAL'), 5, '0'::TEXT)    -- from the earliest step in each task...
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
        ) AND
        EXISTS (
          SELECT name
          FROM jq_task_history
          WHERE
            jq_task_history.name = jq_current_subtasks.task_name AND
            jq_task_history.batch_id = jq_current_subtasks.batch_id AND
            jq_task_history.status = 'running'
        )
    ) AS selected_subtask_id
    INTO selected_subtask;

    UPDATE jq_current_subtasks                                          -- then mark the row we're grabbing...
    SET
      status = 'preparing',
      preparing_started = now()
    WHERE id = selected_subtask
    RETURNING *
    INTO subtask_details;                                               -- and return the data from that row

    RETURN subtask_details;
  END;
  $$;

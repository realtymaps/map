CREATE OR REPLACE FUNCTION jq_get_queue_needs()
  RETURNS TABLE (
    name TEXT,
    quantity INTEGER
  ) AS
  $$
  BEGIN
    RETURN QUERY
    SELECT
      subtasks.queue_name AS name,
      CASE
        WHEN
          COUNT(*) = COUNT(subtasks.status = 'zombie' OR NULL)
        THEN 0  -- if all we have left are zombies, let heroku kill them; but otherwise we need to count them to
                -- prevent deadlock, and likewise need to round up
        ELSE
          ROUND( -- the MIN() calls below are a hack to make the SQL happy, really there will only be 1 value
            (COUNT(*) * MIN(jq_queue_config.priority_factor))
            /
            (MIN(jq_queue_config.subtasks_per_process) * MIN(jq_queue_config.processes_per_dyno))
            + '0.5' -- this bit is to force it to round up, instead of to nearest
          )::INTEGER
      END AS quantity
    FROM jq_current_subtasks AS subtasks
    LEFT JOIN jq_queue_config ON jq_queue_config.name = subtasks.queue_name
    WHERE
      subtasks.status IN ('queued', 'preparing', 'zombie') AND
      NOT subtasks.ignore_until > NOW() AND
      subtasks.task_step IN (
        SELECT task_steps.task_name || '_' || COALESCE(MIN(task_steps.step_num)::TEXT, 'FINAL') AS task_step
        FROM (
          SELECT
            task_steps_tmp.task_name,
            task_steps_tmp.step_num
          FROM jq_current_subtasks AS task_steps_tmp
          GROUP BY
            task_steps_tmp.task_name,
            task_steps_tmp.step_num
          HAVING
            COUNT(
              task_steps_tmp.status IN ('queued', 'running', 'hard fail', 'infrastructure fail') OR
              (task_steps_tmp.status IN ('timeout', 'zombie') AND task_steps_tmp.hard_fail_timeouts = TRUE) OR
              NULL
            ) > 0
        ) AS task_steps
        GROUP BY task_steps.task_name
      )
    GROUP BY subtasks.queue_name;
  END;
  $$
LANGUAGE plpgsql;

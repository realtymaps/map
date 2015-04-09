CREATE TABLE IF NOT EXISTS jq_task_config (
  name TEXT NOT NULL PRIMARY KEY,
  description TEXT,
  data JSON,
  ignore_until TIMESTAMP,
  repeat_period_minutes INTEGER,
  warn_timeout_minutes INTEGER,
  kill_timeout_minutes INTEGER,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS jq_subtask_config (
  name TEXT NOT NULL,
  task_name TEXT NOT NULL,
  queue_name TEXT NOT NULL,
  step_num INTEGER,
  data JSON,
  retry_delay_seconds INTEGER,
  retry_max_count INTEGER,
  hard_fail_timeouts BOOLEAN NOT NULL,
  hard_fail_after_retries BOOLEAN NOT NULL,
  hard_fail_zombies BOOLEAN NOT NULL,
  warn_timeout_seconds INTEGER,
  kill_timeout_seconds INTEGER
);

CREATE TABLE IF NOT EXISTS jq_queue_config (
  name TEXT NOT NULL PRIMARY KEY,
  lock_id SERIAL NOT NULL UNIQUE,
  processes_per_dyno INTEGER NOT NULL,
  subtasks_per_process INTEGER NOT NULL,
  priority_factor FLOAT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS jq_task_history (
  name TEXT NOT NULL,
  data JSON,
  batch_id TEXT NOT NULL UNIQUE,
  started TIMESTAMP NOT NULL DEFAULT NOW(),
  initiator TEXT NOT NULL,
  status_changed TIMESTAMP NOT NULL DEFAULT NOW(),
  finished TIMESTAMP,
  status TEXT NOT NULL DEFAULT 'preparing',
  current BOOLEAN NOT NULL DEFAULT TRUE,
  warn_timeout_minutes INTEGER,
  kill_timeout_minutes INTEGER,
  subtasks_created INTEGER NOT NULL DEFAULT 0,
  subtasks_running INTEGER NOT NULL DEFAULT 0,
  subtasks_finished INTEGER NOT NULL DEFAULT 0,
  subtasks_soft_failed INTEGER NOT NULL DEFAULT 0,
  subtasks_hard_failed INTEGER NOT NULL DEFAULT 0,
  subtasks_infrastructure_failed INTEGER NOT NULL DEFAULT 0,
  subtasks_canceled INTEGER NOT NULL DEFAULT 0,
  subtasks_timeout INTEGER NOT NULL DEFAULT 0,
  subtasks_zombie INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS jq_current_subtasks (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  task_name TEXT NOT NULL,
  queue_name TEXT NOT NULL,
  batch_id TEXT NOT NULL,
  step_num INTEGER,
  task_step TEXT NOT NULL,
  data JSON,
  task_data JSON,
  retry_delay_seconds INTEGER,
  retry_max_count INTEGER,
  retry_num INTEGER NOT NULL DEFAULT 0,
  hard_fail_timeouts BOOLEAN NOT NULL,
  hard_fail_after_retries BOOLEAN NOT NULL,
  hard_fail_zombies BOOLEAN NOT NULL,
  warn_timeout_seconds INTEGER,
  kill_timeout_seconds INTEGER,
  ignore_until TIMESTAMP,
  enqueued TIMESTAMP NOT NULL DEFAULT NOW(),
  started TIMESTAMP,
  finished TIMESTAMP,
  status TEXT NOT NULL DEFAULT 'queued'
);

CREATE TABLE IF NOT EXISTS jq_subtask_error_history (
  id INTEGER NOT NULL,
  name TEXT NOT NULL,
  task_name TEXT NOT NULL,
  queue_name TEXT NOT NULL,
  batch_id TEXT NOT NULL,
  step_num INTEGER,
  task_step TEXT NOT NULL,
  data JSON,
  task_data JSON,
  retry_delay_seconds INTEGER,
  retry_max_count INTEGER,
  retry_num INTEGER NOT NULL DEFAULT 0,
  hard_fail_timeouts BOOLEAN NOT NULL,
  hard_fail_after_retries BOOLEAN NOT NULL,
  hard_fail_zombies BOOLEAN NOT NULL,
  warn_timeout_seconds INTEGER,
  kill_timeout_seconds INTEGER,
  ignore_until TIMESTAMP,
  enqueued TIMESTAMP NOT NULL,
  started TIMESTAMP NOT NULL,
  finished TIMESTAMP,
  status TEXT NOT NULL,
  error TEXT NOT NULL
);




CREATE OR REPLACE FUNCTION jq_lock_key() RETURNS INTEGER IMMUTABLE AS
  $$
  BEGIN
    RETURN (SELECT x'1693F8A6'::INTEGER); -- this is a 32-bit random constant
  END;
  $$
LANGUAGE plpgsql;

-- this function should ideally be run in a transaction by itself, or else in auto-commit mode,
-- because the lock auto-unlocks by itself at the end of the transaction
CREATE OR REPLACE FUNCTION jq_get_next_subtask(source_queue_name TEXT) RETURNS jq_current_subtasks AS
  $$
  DECLARE
    queue_lock_id INTEGER;
    selected_subtask INTEGER;
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
        NOT ignore_until > NOW() AND
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
                status IN ('queued', 'running', 'hard fail', 'infrastructure fail') OR
                (status IN ('timeout', 'zombie') AND hard_fail_timeouts = TRUE) OR
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
    RETURNING *;                                                        -- and return the data from that row
    
  END;
  $$
LANGUAGE plpgsql;


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
          )
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


-- created as as stored proc because knex doesn't have a way to do "update ... from"
CREATE OR REPLACE FUNCTION jq_update_task_counts() RETURNS VOID AS
  $$
  BEGIN
    UPDATE jq_task_history
    SET
      subtasks_created = counts.created,
      subtasks_running = counts.running,
      subtasks_finished = counts.finished,
      subtasks_soft_failed = counts.soft_failed,
      subtasks_hard_failed = counts.hard_failed,
      subtasks_infrastructure_failed = counts.infrastructure_failed,
      subtasks_canceled = counts.canceled,
      subtasks_timeout = counts.timeout,
      subtasks_zombie = counts.zombie
    FROM (
      SELECT
        task_name,
        COUNT(*) AS created,
        COUNT(status = 'running' OR NULL) AS running,
        COUNT(finished IS NULL OR NULL) AS finished,
        COUNT(status = 'soft fail' OR NULL) AS soft_failed,
        COUNT(status = 'hard fail' OR NULL) AS hard_failed,
        COUNT(status = 'infrastructure failed' OR NULL) AS infrastructure_failed,
        COUNT(status = 'canceled' OR NULL) AS canceled,
        COUNT(status = 'timeout' OR NULL) AS timeout,
        COUNT(status = 'zombie' OR NULL) AS zombie
      FROM jq_current_subtasks
      GROUP BY task_name
    ) AS counts
    WHERE
      jq_task_history.name = counts.task_name AND
      jq_task_history.current = TRUE;
  END;
  $$
LANGUAGE plpgsql;

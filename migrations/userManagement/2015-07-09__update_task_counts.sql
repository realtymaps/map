-- change the counting function to not count 'canceled' as 'failed'
CREATE OR REPLACE FUNCTION jq_update_task_counts() RETURNS VOID AS
  $$
  BEGIN
    UPDATE jq_task_history
    SET
      subtasks_created = counts.created,
      subtasks_preparing = counts.preparing,
      subtasks_running = counts.running,
      subtasks_soft_failed = counts.soft_failed,
      subtasks_hard_failed = counts.hard_failed,
      subtasks_infrastructure_failed = counts.infrastructure_failed,
      subtasks_canceled = counts.canceled,
      subtasks_timeout = counts.timeout,
      subtasks_zombie = counts.zombie,
      subtasks_finished = counts.finished,
      subtasks_succeeded = counts.succeeded,
      subtasks_failed = counts.failed
    FROM (
           SELECT
             task_name,
             COUNT(*) AS created,
             COUNT(status = 'preparing' OR NULL) AS preparing,
             COUNT(status = 'running' OR NULL) AS running,
             COUNT(status = 'soft fail' OR NULL) AS soft_failed,
             COUNT(status = 'hard fail' OR NULL) AS hard_failed,
             COUNT(status = 'infrastructure fail' OR NULL) AS infrastructure_failed,
             COUNT(status = 'canceled' OR NULL) AS canceled,
             COUNT(status = 'timeout' OR NULL) AS timeout,
             COUNT(status = 'zombie' OR NULL) AS zombie,
             COUNT(finished IS NOT NULL OR NULL) AS finished,
             COUNT(status = 'success' OR NULL) AS succeeded,
             COUNT(status NOT IN ('queued', 'preparing', 'running', 'success', 'canceled') OR NULL) AS failed
           FROM jq_current_subtasks
           GROUP BY task_name
         ) AS counts
    WHERE
      jq_task_history.name = counts.task_name AND
      jq_task_history.current = TRUE;
  END;
  $$
LANGUAGE plpgsql;

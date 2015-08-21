DROP VIEW IF EXISTS jq_summary;

CREATE VIEW jq_summary AS

SELECT
  CASE 
    WHEN status = 'running' OR status = 'preparing' THEN 'Last Hour'
    ELSE
      (CASE
        WHEN DATE_PART('day', now() - finished) * 24 +
             DATE_PART('hour', now() - finished) < 1
          THEN 'Last Hour'
        WHEN DATE_PART('day', now() - finished) * 24 +
             DATE_PART('hour', now() - finished) < 24
          THEN 'Last Day'
        WHEN DATE_PART('day', now() - finished) < 7
          THEN 'Last 7 Days'
        WHEN DATE_PART('day', now() - finished) < 30
          THEN 'Last 30 Days'
        ELSE 'After 30 Days'
      END) 
  END AS timeframe,
  status,
  COUNT(*) as count
FROM jq_task_history
GROUP BY timeframe, status

UNION

SELECT 
'Current' AS timeframe,
status,
COUNT(CASE WHEN current = true THEN 1 END) AS count
FROM jq_task_history
GROUP BY status, timeframe;

SELECT * FROM jq_summary;

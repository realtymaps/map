CREATE EXTENSION IF NOT EXISTS tablefunc;

DROP VIEW IF EXISTS jq_summary;

CREATE VIEW jq_summary AS
SELECT *
FROM crosstab(
$$
SELECT
  t.timeframe, s.status, CASE WHEN count IS NULL THEN 0 ELSE count END AS num
FROM
(
  SELECT
  unnest(ARRAY['running', 'success', 'hard fail', 'timeout', 'canceled']) status
) s JOIN
(
  SELECT
  unnest(ARRAY['Current', 'Last Hour', 'Last Day', 'Last 7 Days', 'Last 30 Days']) timeframe,
  unnest(ARRAY[1,2,3,4,5]) ord
) t ON 1=1
LEFT JOIN
(
SELECT CASE
  WHEN current = true
    THEN 'Current'
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
END AS timeframe,
status,
COUNT(*) AS count
FROM jq_task_history
GROUP BY status, timeframe
) jq
ON s.status = jq.status AND t.timeframe = jq.timeframe
ORDER BY t.ord, s.status
$$,
$$
SELECT unnest(ARRAY['running', 'success', 'hard fail', 'timeout', 'canceled'])
$$)
AS
t(
  "timeframe" text,
  "running" int,
  "success" int,
  "hard fail" int,
  "timeout" int,
  "canceled" int
);

select * from jq_summary;
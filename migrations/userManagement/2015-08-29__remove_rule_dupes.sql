DELETE FROM data_normalization_config
WHERE concat(data_source_id, '-', list, '-', output) IN (
  SELECT ruleKey
  FROM (
    SELECT concat(data_source_id, '-', list, '-', output) as ruleKey,
    ROW_NUMBER() OVER (partition BY data_source_id, list, output ORDER BY concat(data_source_id, '-', list, '-', output)) AS rnum
    FROM data_normalization_config) t
  WHERE t.rnum > 1);
DROP VIEW IF EXISTS data_health;

CREATE VIEW data_health AS
SELECT * FROM
( SELECT
 data_source_id as load_id,
 COUNT(*) AS load_count,
 COALESCE(SUM(inserted_rows), 0) AS inserted,
 COALESCE(SUM(updated_rows), 0) AS updated,
 COALESCE(SUM(deleted_rows), 0) AS deleted,
 COALESCE(SUM(invalid_rows), 0) AS invalid
FROM data_load_history
GROUP BY data_source_id
) d
LEFT JOIN (
SELECT
  data_source_id as combined_id,
  COUNT(*) AS combined_count,
  SUM(CASE WHEN now() - up_to_date > interval '2 days' THEN 1 ELSE 0 END) AS out_of_date,
  SUM(CASE WHEN geometry IS NULL THEN 1 ELSE 0 END) AS null_geometry,
  SUM(CASE WHEN ungrouped_fields IS NOT NULL THEN 1 ELSE 0 END) AS ungrouped_fields
FROM combined_data
GROUP BY data_source_id
) c
ON d.load_id = c.combined_id;

SELECT * FROM data_health;

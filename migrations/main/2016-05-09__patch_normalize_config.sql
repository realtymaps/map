
WITH joined_data AS (
  SELECT
    field."Interpretation" AS interpretation,
    field."LookupName" AS lookup_name,
    norm.data_source_id AS norm_data_source_id,
    norm.data_source_type AS norm_data_source_type,
    norm.data_type AS norm_data_type,
    norm.output AS norm_output
  FROM config_data_normalization AS norm
    JOIN config_data_source_fields AS field
      ON
        field.data_source_id = norm.data_source_id AND
        field.data_source_type = norm.data_source_type AND
        field.data_list_type = norm.data_type AND
        field."LongName" = norm.output
  WHERE
    norm.list != 'base' AND
    field."Interpretation" != '' AND
    field."Interpretation" IS NOT NULL AND
    field."LookupName" != '' AND
    field."LookupName" IS NOT NULL
)
UPDATE config_data_normalization
SET
  config = jsonb_set(
    jsonb_set(config::JSONB, '{LookupName}', ('"'||joined_data.lookup_name||'"')::JSONB, TRUE)
  , '{Interpretation}', ('"'||joined_data.interpretation||'"')::JSONB, TRUE)::JSON
FROM joined_data
WHERE
  config_data_normalization.data_source_id = joined_data.norm_data_source_id AND
  config_data_normalization.data_source_type = joined_data.norm_data_source_type AND
  config_data_normalization.data_type = joined_data.norm_data_type AND
  config_data_normalization.output = joined_data.norm_output;

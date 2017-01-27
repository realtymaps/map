UPDATE
  config_data_normalization AS normalization
SET
  config = jsonb_set(config::JSONB, '{trim}', 'true'::JSONB, TRUE)::JSON
WHERE
  EXISTS (
    SELECT 1 FROM config_data_source_fields AS fields
    WHERE
      "fields"."DataType" = 'Character'
      AND "normalization"."output" = "fields"."LongName"
      AND "normalization"."data_source_id" = "fields"."data_source_id"
      AND "normalization"."data_type" = "fields"."data_list_type"
  );

UPDATE config_data_normalization AS normalization
SET config = (config::JSONB #- '{doLookup}')::JSON
WHERE data_source_type != 'county';

UPDATE
  config_data_normalization AS normalization
SET
  config = jsonb_set(config::JSONB, '{split}', '","'::JSONB, TRUE)::JSON
WHERE
  EXISTS (
    SELECT 1 FROM config_data_source_fields AS fields
    WHERE
      "normalization"."data_source_type" = 'mls'
      AND "fields"."LookupName" IS NOT NULL AND "fields"."LookupName" != ''
      AND "fields"."Interpretation" = 'LookupMulti'
      AND "normalization"."output" = "fields"."LongName"
      AND "normalization"."data_source_id" = "fields"."data_source_id"
      AND "normalization"."data_type" = "fields"."data_list_type"
  );

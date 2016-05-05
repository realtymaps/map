UPDATE config_data_source_fields SET "DataType" = 'Character' WHERE "SystemName" = '# of Stories';
UPDATE config_data_source_fields SET "DataType" = 'Decimal' WHERE "SystemName" = 'Parking - # of Cars';
UPDATE config_data_source_fields SET "DataType" = 'Decimal' WHERE "SystemName" = 'Lot Size - Acres';
UPDATE config_data_source_fields SET "DataType" = 'Character' WHERE "SystemName" = 'Other Impr Building Area 1';
UPDATE config_data_source_fields SET "DataType" = 'Character' WHERE "SystemName" = 'Other Impr Building Area 2';
UPDATE config_data_source_fields SET "DataType" = 'Character' WHERE "SystemName" = 'Other Impr Building Area 3';
UPDATE config_data_source_fields SET "DataType" = 'Character' WHERE "SystemName" = 'Other Impr Building Area 4';
UPDATE config_data_source_fields SET "DataType" = 'Character' WHERE "SystemName" = 'Other Impr Building Area 5';

UPDATE config_data_normalization SET config = jsonb_set(config::JSONB, '{DataType}', '"Character"'::JSONB, TRUE)::JSON WHERE output = '# of Stories';
UPDATE config_data_normalization SET config = jsonb_set(config::JSONB, '{DataType}', '"Decimal"'::JSONB, TRUE)::JSON WHERE output = 'Parking - # of Cars';
UPDATE config_data_normalization SET config = jsonb_set(config::JSONB, '{DataType}', '"Decimal"'::JSONB, TRUE)::JSON WHERE output = 'Lot Size - Acres';
UPDATE config_data_normalization SET config = jsonb_set(config::JSONB, '{DataType}', '"Character"'::JSONB, TRUE)::JSON WHERE output = 'Other Impr Building Area 1';
UPDATE config_data_normalization SET config = jsonb_set(config::JSONB, '{DataType}', '"Character"'::JSONB, TRUE)::JSON WHERE output = 'Other Impr Building Area 2';
UPDATE config_data_normalization SET config = jsonb_set(config::JSONB, '{DataType}', '"Character"'::JSONB, TRUE)::JSON WHERE output = 'Other Impr Building Area 3';
UPDATE config_data_normalization SET config = jsonb_set(config::JSONB, '{DataType}', '"Character"'::JSONB, TRUE)::JSON WHERE output = 'Other Impr Building Area 4';
UPDATE config_data_normalization SET config = jsonb_set(config::JSONB, '{DataType}', '"Character"'::JSONB, TRUE)::JSON WHERE output = 'Other Impr Building Area 5';

UPDATE
  config_data_normalization AS normalization SET config = jsonb_set(config::JSONB, '{doLookup}', 'true'::JSONB, TRUE)::JSON
WHERE
  EXISTS (
  SELECT 1 FROM config_data_source_fields AS fields
  WHERE
    "fields"."LookupName" IS NOT NULL AND "fields"."LookupName" != ''
    AND "normalization"."output" = "fields"."LongName"
    AND "normalization"."data_source_id" = "fields"."data_source_id"
    AND "normalization"."data_type" = "fields"."data_list_type"
);

UPDATE config_data_normalization SET config = jsonb_set(config::JSONB, '{doLookup}', 'false'::JSONB, TRUE)::JSON
WHERE output = '# of Stories';
UPDATE config_data_normalization SET
  config = jsonb_set(config::JSONB, '{advanced}', 'true'::JSONB, TRUE)::JSON,
  transform = '[validators.numStories({})]'
WHERE output = '# of Stories';

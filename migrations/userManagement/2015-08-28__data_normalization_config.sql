ALTER TABLE data_normalization_config ADD COLUMN data_source_type TEXT;
ALTER TABLE data_normalization_config ADD COLUMN data_type TEXT;

UPDATE data_normalization_config SET data_source_type = 'mls', data_type = 'listing';

ALTER TABLE data_normalization_config ALTER COLUMN data_source_type SET NOT NULL;
ALTER TABLE data_normalization_config ALTER COLUMN data_type SET NOT NULL;

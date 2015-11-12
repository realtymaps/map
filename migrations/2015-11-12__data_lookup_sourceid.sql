ALTER TABLE config_data_source_lookups ADD COLUMN data_source_id TEXT;
UPDATE config_data_source_lookups SET data_source_id = 'CoreLogic';
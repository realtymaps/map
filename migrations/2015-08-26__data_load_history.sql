ALTER TABLE data_load_history ADD COLUMN data_type TEXT;
UPDATE data_load_history SET data_type = 'listing';
ALTER TABLE data_load_history ALTER COLUMN data_type SET NOT NULL;

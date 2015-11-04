ALTER TABLE data_load_history RENAME COLUMN valid_rows TO inserted_rows;
ALTER TABLE data_load_history ADD COLUMN updated_rows INTEGER;
ALTER TABLE data_load_history ADD COLUMN deleted_rows INTEGER;

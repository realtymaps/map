ALTER TABLE data_load_history ADD COLUMN cleaned BOOLEAN DEFAULT FALSE NOT NULL;
DELETE FROM data_load_history WHERE raw_table_name IS NULL AND data_source_type = 'mls';

TRUNCATE data_combined;
ALTER TABLE data_combined ALTER COLUMN year_built TYPE JSON USING NULL;

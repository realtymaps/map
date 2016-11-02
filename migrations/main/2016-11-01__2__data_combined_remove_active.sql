
DROP INDEX IF EXISTS data_combined_data_source_id_data_source_uuid_idx;
DELETE FROM data_combined WHERE active = FALSE;
ALTER TABLE data_combined DROP COLUMN active;

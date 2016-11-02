
DROP INDEX IF EXISTS data_agent_data_source_id_data_source_uuid_idx;
DELETE FROM data_agent WHERE active = FALSE;
ALTER TABLE data_agent DROP COLUMN active;

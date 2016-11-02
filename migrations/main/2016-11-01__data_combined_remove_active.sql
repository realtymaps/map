
TRUNCATE jq_current_subtasks;
DELETE FROM jq_task_history WHERE current = TRUE;

DELETE FROM jq_task_config WHERE name = 'cleanup_deleteInactiveRows';


DROP INDEX IF EXISTS data_combined_data_source_id_data_source_uuid_idx;
DELETE FROM data_combined WHERE active = FALSE;
ALTER TABLE data_combined DROP COLUMN active;
CREATE INDEX data_combined_data_source_id_data_source_uuid_idx ON data_combined USING btree (data_source_id, data_source_uuid);

DROP INDEX IF EXISTS data_agent_data_source_id_data_source_uuid_idx;
DELETE FROM data_agent WHERE active = FALSE;
ALTER TABLE data_agent DROP COLUMN active;
CREATE INDEX data_agent_data_source_id_data_source_uuid_idx ON data_combined USING btree (data_source_id, data_source_uuid);

DELETE FROM data_parcel WHERE active = FALSE;
ALTER TABLE data_parcel DROP COLUMN active;

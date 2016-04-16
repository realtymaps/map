-- I'm removing data_source_type from the constraint/upsert and queries, so it will be an informational field only
DROP INDEX "config_data_source_fields_SystemName_data_source_id_data_so_idx";
CREATE UNIQUE INDEX ON config_data_source_fields ("SystemName", data_source_id, data_list_type);


TRUNCATE config_data_source_lookups;
-- adding data_source_type as an informational field to be consistent with config_data_source_fields
ALTER TABLE config_data_source_lookups ADD COLUMN data_source_type TEXT NOT NULL;
ALTER TABLE config_data_source_lookups ADD COLUMN data_list_type TEXT NOT NULL;
CREATE UNIQUE INDEX ON config_data_source_lookups ("LookupName", "Value", data_source_id, data_list_type);

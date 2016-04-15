-- I'm removing data_source_type from the constraint/upsert and queries, so it will be an informational field only
DROP INDEX "config_data_source_fields_SystemName_data_source_id_data_so_idx";
CREATE UNIQUE INDEX ON config_data_source_fields ("SystemName", data_source_id, data_list_type);

-- don't need corelogic data slowing queries down
DELETE FROM config_data_source_lookups WHERE data_source_id = 'corelogic';

-- adding data_source_type as an informational field to be consistent with config_data_source_fields
ALTER TABLE config_data_source_lookups ADD COLUMN data_source_type TEXT;
UPDATE config_data_source_lookups SET data_source_type = 'county';
ALTER TABLE config_data_source_lookups ALTER COLUMN data_source_type SET NOT NULL;
CREATE UNIQUE INDEX ON config_data_source_lookups ("LookupName", "LongValue", data_source_id);

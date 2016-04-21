-- this is so I can upsert on the table
CREATE UNIQUE INDEX ON config_data_source_fields ("SystemName", data_source_id, data_source_type, data_list_type);


CREATE INDEX data_combined_data_source_id_data_source_uuid_idx ON data_combined USING btree (data_source_id, data_source_uuid);

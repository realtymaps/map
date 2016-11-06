
CREATE INDEX data_agent_data_source_id_data_source_uuid_idx ON data_agent USING btree (data_source_id, data_source_uuid);

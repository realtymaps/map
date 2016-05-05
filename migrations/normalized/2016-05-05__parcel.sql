CREATE UNIQUE INDEX parcel_data_source_id_data_source_uuid_idx ON parcel USING btree (data_source_id, data_source_uuid);
CREATE INDEX parcel_batch_id_idx ON parcel USING btree (batch_id);
CREATE INDEX  parcel_data_source_id_deleted_idx ON parcel USING btree(data_source_id, deleted);
CREATE INDEX  parcel_data_source_id_inserted_idx ON parcel USING btree(data_source_id, inserted);
CREATE INDEX  parcel_data_source_id_updated_idx ON parcel USING btree(data_source_id, updated);

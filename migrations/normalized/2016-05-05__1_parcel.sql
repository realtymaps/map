CREATE INDEX IF NOT EXISTS parcel_batch_id_idx ON parcel USING btree (batch_id);
CREATE INDEX  IF NOT EXISTS parcel_data_source_id_deleted_idx ON parcel USING btree(data_source_id, deleted);
CREATE INDEX  IF NOT EXISTS parcel_data_source_id_inserted_idx ON parcel USING btree(data_source_id, inserted);
CREATE INDEX  IF NOT EXISTS  parcel_data_source_id_updated_idx ON parcel USING btree(data_source_id, updated);

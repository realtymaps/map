DELETE FROM parcel;

CREATE INDEX IF NOT EXISTS parcel_batch_id_idx ON parcel USING btree (batch_id);
CREATE INDEX IF NOT EXISTS parcel_data_source_id_idx ON parcel USING btree (data_source_id);
CREATE INDEX  IF NOT EXISTS parcel_data_source_id_deleted_idx ON parcel USING btree(data_source_id, deleted);
CREATE INDEX  IF NOT EXISTS parcel_data_source_id_inserted_idx ON parcel USING btree(data_source_id, inserted);
CREATE INDEX  IF NOT EXISTS  parcel_data_source_id_updated_idx ON parcel USING btree(data_source_id, updated);

DROP INDEX IF EXISTS parcel_data_source_id_data_source_uuid_batch_id_idx;

CREATE UNIQUE INDEX parcel_data_source_id_data_source_uuid_batch_id_idx
ON parcel USING btree (data_source_id, data_source_uuid, batch_id);

CREATE UNIQUE INDEX parcel_data_source_id_data_source_id_rm_property_id_active_idx
ON parcel USING btree (data_source_id, rm_property_id, active);

DROP INDEX IF EXISTS parcel_data_source_id_data_source_uuid_idx;
CREATE INDEX parcel_data_source_id_data_source_uuid_idx ON parcel USING btree (data_source_id, data_source_uuid);

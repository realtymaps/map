DROP INDEX IF EXISTS parcel_data_source_id_data_source_uuid_idx;
CREATE INDEX parcel_data_source_id_data_source_uuid_idx ON parcel USING btree (data_source_id, data_source_uuid);
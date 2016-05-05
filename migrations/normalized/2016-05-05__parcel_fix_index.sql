DROP INDEX parcel_data_source_id_data_source_uuid_idx;

CREATE UNIQUE INDEX parcel_data_source_id_data_source_uuid_batch_id_idx
ON parcel USING btree (data_source_id, data_source_uuid, batch_id);

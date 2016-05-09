DROP INDEX IF EXISTS parcel_data_source_id_data_source_uuid_batch_id_idx;

CREATE INDEX parcel_data_source_id_data_source_uuid_batch_id_idx
ON parcel USING btree (data_source_id, data_source_uuid, batch_id);


DROP INDEX IF EXISTS parcel_data_source_id_data_source_id_rm_property_id_active_idx;

CREATE INDEX parcel_data_source_id_data_source_id_rm_property_id_active_idx
ON parcel USING btree (data_source_id, rm_property_id, active);

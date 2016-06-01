DROP TRIGGER insert_modified_geom_jsons_parcel ON parcel;
DROP TRIGGER update_modified_geom_jsons_parcel ON parcel;
DROP TRIGGER update_modified_time_parcel ON parcel;

DROP INDEX parcel_geom_polys_raw_idx;
DROP INDEX parcel_geom_point_raw_idx;

DROP INDEX parcel_geom_polys_json_idx;
DROP INDEX parcel_geom_point_json_idx;

DROP INDEX parcel_data_source_id_inserted_idx;
DROP INDEX parcel_data_source_id_updated_idx;
DROP INDEX parcel_data_source_id_deleted_idx;

DROP INDEX parcel_data_source_id_idx;

DROP INDEX parcel_data_source_id_data_source_uuid_idx;
DROP INDEX parcel_data_source_id_data_source_uuid_batch_id_idx;

DROP INDEX parcel_data_source_id_data_source_id_rm_property_id_active_idx;
DROP INDEX parcel_batch_id_idx;


CREATE INDEX parcel_rm_property_id_data_source_id_active_idx
ON parcel USING btree (rm_property_id, data_source_id, active);

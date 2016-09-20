DROP INDEX IF EXISTS data_combined_rm_property_id_data_source_id_idx;
DROP INDEX IF EXISTS combined_data_data_source_id_rm_property_id_update_source_b_idx;


DROP INDEX IF EXISTS data_combined_rm_property_id_idx;
CREATE INDEX data_combined_rm_property_id_idx ON data_combined USING btree (rm_property_id);

DROP INDEX IF EXISTS data_combined_address_idx;
CREATE INDEX data_combined_address_idx ON data_combined USING gin (address);

DROP INDEX IF EXISTS combined_data_geometry_raw_idx;
CREATE INDEX data_combined_geometry_raw_idx ON data_combined USING gist (geometry_raw);

DROP INDEX IF EXISTS data_combined_baths_total_idx;
CREATE INDEX data_combined_baths_total_idx ON data_combined USING btree (baths_total);

DROP INDEX IF EXISTS data_combined_fips_code_idx;
CREATE INDEX data_combined_fips_code_idx ON data_combined USING btree (fips_code);

DROP INDEX IF EXISTS data_combined_status_idx;
CREATE INDEX data_combined_status_idx ON data_combined USING btree (status);

DROP INDEX IF EXISTS data_combined_close_date_idx;
CREATE INDEX data_combined_close_date_idx ON data_combined USING btree (close_date);

DROP INDEX IF EXISTS data_combined_property_type_idx;
CREATE INDEX data_combined_property_type_idx ON data_combined USING btree (property_type);

DROP INDEX IF EXISTS data_combined_price_idx;
CREATE INDEX data_combined_price_idx ON data_combined USING btree (price);

DROP INDEX IF EXISTS data_combined_bedrooms_idx;
CREATE INDEX data_combined_bedrooms_idx ON data_combined USING btree (bedrooms);




DROP INDEX IF EXISTS parcel_rm_property_id_data_source_id_active_idx;
DROP INDEX IF EXISTS parcel_carto_idx;

CREATE INDEX parcel_fips_code_idx ON data_parcel USING btree (fips_code);

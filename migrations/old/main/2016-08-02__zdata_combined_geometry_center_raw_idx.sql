DROP INDEX combined_data_geometry_center_raw_idx;

-- cluster cannot be run on partial indexes
CREATE INDEX combined_data_geometry_center_raw_idx ON data_combined USING GIST (geometry_center_raw);

ALTER TABLE data_combined CLUSTER ON combined_data_geometry_center_raw_idx;

CLUSTER data_combined using combined_data_geometry_center_raw_idx;

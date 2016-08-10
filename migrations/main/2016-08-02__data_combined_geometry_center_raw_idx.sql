CREATE INDEX combined_data_geometry_center_raw_idx ON data_combined USING GIST (geometry_center_raw) WHERE active IS TRUE;

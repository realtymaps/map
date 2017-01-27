ALTER TABLE lookup_fips_codes
	ADD COLUMN geometry_raw geometry,
	ADD COLUMN geometry_center_raw geometry,
	ADD COLUMN geometry json,
	ADD COLUMN geometry_center json;

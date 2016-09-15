CREATE INDEX parcel_bounds_idx ON data_parcel USING GIST (geometry_raw);
CREATE INDEX parcel_carto_idx ON data_parcel (fips_code, active) WHERE active = TRUE;

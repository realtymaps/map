CREATE INDEX idx_parcels_rm_property_id ON parcels USING btree (rm_property_id);
CREATE INDEX idx_parcels_fips_code_id ON parcels USING btree (fips_code);
CREATE INDEX idx_the_geom_fips_code_id ON parcels USING gist (the_geom);

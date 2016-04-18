-- NOTE: REQUIRES POSTGRES ON NORMALIZED
CREATE TABLE parcel (
  rm_property_id text NOT NULL,
  data_source_id text NOT NULL,
  batch_id text NOT NULL,
  fips_code int4 NOT NULL,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),

  street_address_num text,
  street_unit_num text,
	geom_polys_raw public.geometry,
	geom_point_raw public.geometry,
	geom_polys_json jsonb,
	geom_point_json jsonb,
  PRIMARY KEY (rm_property_id) NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);

CREATE TRIGGER update_modified_time_parcel
BEFORE UPDATE ON parcel
FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

CREATE INDEX  parcel_geom_polys_raw_idx ON parcel USING gist(geom_polys_raw gist_geometry_ops_2d) WITH (BUFFERING = OFF);
CREATE INDEX  parcel_geom_point_raw_idx ON parcel USING gist(geom_point_raw gist_geometry_ops_2d) WITH (BUFFERING = OFF);

CREATE INDEX  parcel_geom_polys_json_idx ON parcel USING gin (geom_polys_json);
CREATE INDEX  parcel_geom_point_json_idx ON parcel USING gin (geom_point_json);

CREATE INDEX  parcel_rm_property_id_idx ON parcel USING btree(rm_property_id);

CREATE TRIGGER update_modified_geom_jsons_parcel
  BEFORE UPDATE ON parcel
  FOR EACH ROW EXECUTE PROCEDURE update_geom_jsons_from_geom_raws();

CREATE TRIGGER insert_modified_geom_jsons_parcel
  BEFORE INSERT ON parcel
  FOR EACH ROW EXECUTE PROCEDURE update_geom_jsons_from_geom_raws();

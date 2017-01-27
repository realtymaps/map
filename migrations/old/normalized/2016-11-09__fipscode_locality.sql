CREATE TABLE fipscode_locality (
  state TEXT NOT NULL,
  county TEXT NOT NULL,
  code TEXT NOT NULL,
  batch_id TEXT NOT NULL,
  geometry_raw geometry,
	geometry_center_raw geometry,
	geometry json,
	geometry_center json,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_raw_id int
)
WITH (OIDS=FALSE);


CREATE TRIGGER update_modified_time_fipsode_locality
BEFORE UPDATE ON fipscode_locality
FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

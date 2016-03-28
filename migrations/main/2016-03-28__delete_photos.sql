CREATE TABLE delete_photos (
  id serial,
  key varchar NOT NULL UNIQUE,
  batch_id text NOT NULL,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);

CREATE TRIGGER update_modified_time_delete_photos
BEFORE UPDATE ON delete_photos
FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

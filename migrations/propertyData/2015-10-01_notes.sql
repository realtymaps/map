CREATE TABLE notes (
	id serial,
	auth_user_id int4,
	project_id int4,
	text varchar NOT NULL,
	title varchar(100),
	comments jsonb,
  geom_point_raw geometry(Point,26910),
  geom_point_json json,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
	PRIMARY KEY (id),
  CONSTRAINT fk_auth_user_id_notes FOREIGN KEY (auth_user_id) REFERENCES auth_user (id) ON UPDATE CASCADE ON DELETE CASCADE
)
WITH (OIDS=FALSE);

CREATE TRIGGER update_modified_time_notes
  BEFORE UPDATE ON notes
  FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

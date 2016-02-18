-- removing shapes from profile so shapes can be shared project based
ALTER TABLE user_profile DROP COLUMN drawn_shapes;

-- One Project to many Shapes
CREATE TABLE user_drawn_shapes (
	id serial,
	auth_user_id int4,
	project_id int4,
  geom_point_raw geometry(Point,26910),
	geom_polys_raw geometry(MultiPolygon,26910),
  geom_point_json json,
	geom_polys_json json,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
	PRIMARY KEY (id),
  CONSTRAINT fk_auth_user_id_user_drawn_shapes FOREIGN KEY (auth_user_id) REFERENCES auth_user (id) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_project_id_user_drawn_shapes FOREIGN KEY (project_id) REFERENCES user_project (id) ON UPDATE CASCADE ON DELETE CASCADE
)
WITH (OIDS=FALSE);

CREATE TRIGGER update_modified_time_user_drawn_shapes
BEFORE UPDATE ON user_drawn_shapes
FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

DROP TRIGGER IF EXISTS update_modified_geom_raw_user_drawn_shapes ON user_drawn_shapes;
DROP TRIGGER IF EXISTS insert_modified_geom_raw_user_drawn_shapes ON user_drawn_shapes;

CREATE TRIGGER update_modified_geom_raw_user_drawn_shapes
BEFORE UPDATE ON user_drawn_shapes
FOR EACH ROW EXECUTE PROCEDURE update_geom_raw_from_geom_json();

CREATE TRIGGER insert_modified_geom_raw_user_drawn_shapes
BEFORE INSERT ON user_drawn_shapes
FOR EACH ROW EXECUTE PROCEDURE update_geom_raw_from_geom_json();

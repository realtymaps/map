-- UPDATE DEPENDENT TABLES

DROP TRIGGER IF EXISTS update_modified_geom_point_raw_notes ON user_notes;
DROP TRIGGER IF EXISTS insert_modified_geom_point_raw_notes ON user_notes;

DROP FUNCTION IF EXISTS update_geom_point_raw_from_geom_point_json();

-- end Drop

CREATE OR REPLACE FUNCTION update_geom_raw_from_geom_json() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.geom_point_json IS NOT NULL THEN
    NEW.geom_point_raw = ST_GeomFromGeoJSON(NEW.geom_point_json::text);
  END IF;

  IF NEW.geom_polys_json IS NOT NULL THEN
    NEW.geom_polys_raw = ST_GeomFromGeoJSON(NEW.geom_polys_json::text);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- RENAME to Generic geom
CREATE TRIGGER update_modified_geom_raw_notes
BEFORE UPDATE ON user_notes
FOR EACH ROW EXECUTE PROCEDURE update_geom_raw_from_geom_json();

CREATE TRIGGER insert_modified_geom_raw_notes
BEFORE INSERT ON user_notes
FOR EACH ROW EXECUTE PROCEDURE update_geom_raw_from_geom_json();

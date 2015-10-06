CREATE TRIGGER update_modified_geom_point_raw_notes
  BEFORE UPDATE ON notes
  FOR EACH ROW EXECUTE PROCEDURE update_geom_point_raw_from_geom_point_json();

  CREATE TRIGGER insert_modified_geom_point_raw_notes
    BEFORE INSERT ON notes
    FOR EACH ROW EXECUTE PROCEDURE update_geom_point_raw_from_geom_point_json();

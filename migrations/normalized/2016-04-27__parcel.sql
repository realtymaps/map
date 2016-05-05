CREATE TRIGGER update_geom_point_raw_from_geom_polys_raw_parcel
  BEFORE UPDATE ON parcel
  FOR EACH ROW EXECUTE PROCEDURE update_geom_point_raw_from_geom_polys_raw();

CREATE TRIGGER insert_geom_point_raw_from_geom_polys_raw_parcel
  BEFORE INSERT ON parcel
  FOR EACH ROW EXECUTE PROCEDURE update_geom_point_raw_from_geom_polys_raw();

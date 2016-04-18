CREATE OR REPLACE FUNCTION update_geom_jsons_from_geom_raws() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.geom_point_raw IS NOT NULL THEN
    NEW.geom_point_json = ST_AsGeoJSON(NEW.geom_point_raw::geometry);
  END IF;

  IF NEW.geom_polys_raw IS NOT NULL THEN
    NEW.geom_polys_json = ST_AsGeoJSON(NEW.geom_polys_raw::geometry);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

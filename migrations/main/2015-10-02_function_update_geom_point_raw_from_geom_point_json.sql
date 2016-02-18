CREATE OR REPLACE FUNCTION update_geom_point_raw_from_geom_point_json() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.geom_point_json IS NOT NULL THEN
    NEW.geom_point_raw = ST_GeomFromGeoJSON(NEW.geom_point_json::text);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

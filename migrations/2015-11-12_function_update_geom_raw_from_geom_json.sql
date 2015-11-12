CREATE OR REPLACE FUNCTION update_geom_raw_from_geom_json() RETURNS TRIGGER AS $$
BEGIN
  IF col_exists(TG_TABLE_NAME, 'geom_point_json'::text) THEN
    IF NEW.geom_point_json IS NOT NULL THEN
      NEW.geom_point_raw = ST_GeomFromGeoJSON(NEW.geom_point_json::text);
    END IF;
  END IF;

  IF col_exists(TG_TABLE_NAME, 'geom_polys_json'::text) THEN
    IF NEW.geom_polys_json IS NOT NULL THEN
      NEW.geom_polys_raw = ST_GeomFromGeoJSON(NEW.geom_polys_json::text);
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

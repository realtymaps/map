CREATE FUNCTION update_geom_raw_from_geom_json() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF col_exists(TG_TABLE_NAME::regclass, 'geometry_center'::text) THEN
    IF NEW.geometry_center IS NOT NULL THEN
      NEW.geometry_center_raw = ST_GeomFromGeoJSON(NEW.geometry_center::text);
    END IF;
  END IF;

  IF col_exists(TG_TABLE_NAME::regclass, 'geometry'::text) THEN
    IF NEW.geometry IS NOT NULL THEN
      NEW.geometry_raw = ST_GeomFromGeoJSON(NEW.geometry::text);
    END IF;
  END IF;

  IF col_exists(TG_TABLE_NAME::regclass, 'geometry_line'::text) THEN
    IF NEW.geometry_line IS NOT NULL THEN
      NEW.geometry_line_raw = ST_GeomFromGeoJSON(NEW.geometry_line::text);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;



CREATE OR REPLACE FUNCTION update_geom_point_raw_from_geom_polys_raw() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.geom_polys_raw IS NOT NULL THEN
    NEW.geom_point_raw = ST_Centroid(NEW.geom_polys_raw::geometry);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE INDEX mv_property_details_geom_point_raw_idx ON
  mv_property_details USING GIST (geom_point_raw);

CREATE INDEX mv_property_details_geom_polys_raw_idx ON
  mv_property_details USING GIST (geom_polys_raw);

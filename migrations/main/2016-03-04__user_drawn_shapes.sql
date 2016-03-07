CREATE INDEX user_drawn_shapes_geom_point_raw_idx ON
  user_drawn_shapes USING GIST (geom_point_raw);

CREATE INDEX user_drawn_shapes_geom_polys_raw_idx ON
  user_drawn_shapes USING GIST (geom_polys_raw);

CREATE INDEX user_drawn_shapes_geom_line_raw_idx ON
  user_drawn_shapes USING GIST (geom_line_raw);

ALTER TABLE user_drawn_shapes ALTER COLUMN shape_extras TYPE jsonb;

CREATE INDEX user_drawn_shapes_shape_extras_idx ON
  user_drawn_shapes USING gin (shape_extras);

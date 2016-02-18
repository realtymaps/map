SELECT f_add_col('user_drawn_shapes', 'shape_extras', 'json');
ALTER TABLE user_drawn_shapes DROP COLUMN geom_polys_raw;
ALTER TABLE user_drawn_shapes ADD COLUMN geom_polys_raw geometry(Polygon,26910);
ALTER TABLE user_drawn_shapes ADD COLUMN geom_line_raw geometry(LineString,26910);
ALTER TABLE user_drawn_shapes ADD COLUMN geom_line_json json;

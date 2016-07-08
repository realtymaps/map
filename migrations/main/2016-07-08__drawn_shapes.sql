ALTER TABLE user_drawn_shapes rename column geom_polys_raw to geometry_raw;
ALTER TABLE user_drawn_shapes rename column geom_polys_json to geometry;
ALTER TABLE user_drawn_shapes rename column geom_point_raw to geometry_center_raw;
ALTER TABLE user_drawn_shapes rename column geom_point_json to geometry_center;
ALTER TABLE user_drawn_shapes rename column geom_line_raw to geometry_line_raw;
ALTER TABLE user_drawn_shapes rename column geom_line_json to geometry_line;

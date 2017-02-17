ALTER TABLE public.user_drawn_shapes SET (autovacuum_vacuum_scale_factor = 0.0);
ALTER TABLE public.user_drawn_shapes SET (autovacuum_vacuum_threshold = 1000);
ALTER TABLE public.user_drawn_shapes SET (autovacuum_analyze_scale_factor = 0.0);
ALTER TABLE public.user_drawn_shapes SET (autovacuum_analyze_threshold = 1000);

CREATE INDEX IF NOT EXISTS user_drawn_shapes_project_id_idx ON user_drawn_shapes (project_id);
CREATE INDEX IF NOT EXISTS user_drawn_shapes_auth_user_id_idx ON user_drawn_shapes (auth_user_id);
CREATE INDEX IF NOT EXISTS user_drawn_shapes_area_name_idx ON user_drawn_shapes (area_name);

CLUSTER user_drawn_shapes USING user_drawn_shapes_project_id_idx;
ANALYZE user_drawn_shapes;

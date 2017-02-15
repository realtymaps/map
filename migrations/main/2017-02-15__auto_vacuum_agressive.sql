-- ordered from largest tables to smallest (rows)

-- NOTE: About the adjustments to auto vacuum and analyze
-- https://www.netiq.com/documentation/cloud-manager-2-5/ncm-install/data/vacuum.html
-- Modifying a specific schema.table's autovavuum settings to happen much more frequently.
-- Have no scale helps very large tables by default . Since:
-- PostgreSQL database tables are auto-vacuumed by default when 20% of the rows plus 50 rows are inserted, updated, or deleted. (autovacuum_vacuum_*)
-- Tables are auto-analyzed when a threshold is met for 10% of the rows plus 50 rows. (autovacuum_analyze_*)

-- 10 mil
ALTER TABLE public.data_parcel SET (autovacuum_vacuum_scale_factor = 0.0);
ALTER TABLE public.data_parcel SET (autovacuum_vacuum_threshold = 1000);
ALTER TABLE public.data_parcel SET (autovacuum_analyze_scale_factor = 0.0);
ALTER TABLE public.data_parcel SET (autovacuum_analyze_threshold = 1000);

-- 7 mil
ALTER TABLE public.data_combined SET (autovacuum_vacuum_scale_factor = 0.0);
ALTER TABLE public.data_combined SET (autovacuum_vacuum_threshold = 1000);
ALTER TABLE public.data_combined SET (autovacuum_analyze_scale_factor = 0.0);
ALTER TABLE public.data_combined SET (autovacuum_analyze_threshold = 1000);

-- 5mil
ALTER TABLE public.data_photo SET (autovacuum_vacuum_scale_factor = 0.0);
ALTER TABLE public.data_photo SET (autovacuum_vacuum_threshold = 1000);
ALTER TABLE public.data_photo SET (autovacuum_analyze_scale_factor = 0.0);
ALTER TABLE public.data_photo SET (autovacuum_analyze_threshold = 1000);

-- 500k
ALTER TABLE public.data_agent SET (autovacuum_vacuum_scale_factor = 0.0);
ALTER TABLE public.data_agent SET (autovacuum_vacuum_threshold = 1000);
ALTER TABLE public.data_agent SET (autovacuum_analyze_scale_factor = 0.0);
ALTER TABLE public.data_agent SET (autovacuum_analyze_threshold = 1000);

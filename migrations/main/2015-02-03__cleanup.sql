DROP VIEW IF EXISTS v_parcel_base;
DROP TABLE IF EXISTS county_data1_copy;
DROP TABLE IF EXISTS temp_mls_data_2;
DROP TABLE IF EXISTS schema_version;
DROP FUNCTION IF EXISTS reset_materialized_view_query(id TEXT);
DROP FUNCTION IF EXISTS reset_materialized_view(id TEXT);
DROP FUNCTION IF EXISTS make_null(ANYELEMENT, ANYELEMENT);

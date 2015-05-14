INSERT INTO view_definitions (view_id, clause_type, definition) VALUES ('parcels', 'INDEX', 'rm_property_id');

SELECT dirty_materialized_view('parcels', FALSE);

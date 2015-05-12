--DELETE FROM view_definitions WHERE view_id = 'parcels';

INSERT INTO view_definitions (view_id, clause_type, definition, name) VALUES ('parcels', 'SELECT', 'fips', 'fips_code');

INSERT INTO view_definitions (view_id, clause_type, definition) VALUES ('parcels', 'FROM', 'parcels');

SELECT dirty_materialized_view('parcels', FALSE);

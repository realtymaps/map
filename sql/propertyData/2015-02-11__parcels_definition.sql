DELETE FROM view_definitions WHERE view_id = 'parcels';

INSERT INTO view_definitions (view_id, clause_type, definition, name) VALUES ('parcels', 'SELECT', 'rm_property_id', 'rm_property_id');
INSERT INTO view_definitions (view_id, clause_type, definition, name) VALUES ('parcels', 'SELECT', $q$build_street_address_num('', sthsnum, '', '') || ignore_blank(' ',build_street_address_unit(stunitprfx, stunitnum),'')$q$, 'street_address_num');
INSERT INTO view_definitions (view_id, clause_type, definition, name) VALUES ('parcels', 'SELECT', 'geom_polys', 'geom_polys_raw');
INSERT INTO view_definitions (view_id, clause_type, definition, name) VALUES ('parcels', 'SELECT', 'geom_point', 'geom_point_raw');
INSERT INTO view_definitions (view_id, clause_type, definition, name) VALUES ('parcels', 'SELECT', 'ST_AsGeoJSON(geom_polys)::JSON', 'geom_polys_json');
INSERT INTO view_definitions (view_id, clause_type, definition, name) VALUES ('parcels', 'SELECT', 'ST_AsGeoJSON(geom_point)::JSON', 'geom_point_json');

INSERT INTO view_definitions (view_id, clause_type, definition) VALUES ('parcels', 'FROM', 'parcels');

INSERT INTO view_definitions (view_id, clause_type, definition, aux) VALUES ('parcels', 'INDEX', 'geom_polys_raw', 'GIST');

SELECT dirty_materialized_view('parcels', FALSE);

--http://www.sqlines.com/postgresql/how-to/return_result_set_from_stored_procedure

/* Example Usage

Useful for getting column names generated from views to create concise queries.

SELECT * get_columns_type ('cursor','mv_property_details');

Sample RETURN:
col            |           types
------------------------------+------------------------------
rm_property_id               | character varying(64)
has_mls                      | boolean
has_tax                      | boolean
has_deed                     | boolean
street_address_num           | text
street_address_name          | text
street_address_unit          | text
city                         | text
state                        | text
zip                          | text
geom_polys_raw               | geometry(MultiPolygon,26910)
geom_point_raw               | geometry(Point,26910)
*/
CREATE OR REPLACE FUNCTION get_columns_type(tableName TEXT) RETURNS TABLE(cols name, types text) AS $$
DECLARE
    tmp TEXT;
BEGIN
  tmp := concat('^(',tableName,')$');
  RETURN QUERY
  SELECT
  	a.attname,
	pg_catalog.format_type(a.atttypid, a.atttypmod)
  FROM
  	pg_catalog.pg_attribute a
  WHERE
  	a.attnum > 0
  	AND NOT a.attisdropped
  	AND a.attrelid = (
  		SELECT c.oid
  		FROM pg_catalog.pg_class c
  			LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
  		WHERE c.relname ~ tmp
  			AND pg_catalog.pg_table_is_visible(c.oid)
  	);
END;
$$ LANGUAGE plpgsql;

/* Example Usage

Useful for getting column names generated from views to create concise queries.


SELECT cols from get_columns ('cursor','mv_property_details');

Sample RETURN:

cols
------------------------------
rm_property_id
has_mls
has_tax
has_deed
street_address_num
street_address_name
street_address_unit
city
state
zip
*/
CREATE OR REPLACE FUNCTION get_columns(tableName TEXT) RETURNS TABLE(cols name) AS $$
BEGIN
  RETURN QUERY EXECUTE 'SELECT cols from get_columns_type('''||tableName||''');';
END;
$$ LANGUAGE plpgsql;


/* Example Usage

Useful for getting column names generated from views to create concise queries.


SELECT cols from get_columns_array ('mv_property_details');
or
SELECT get_columns_array ('mv_property_details');

Sample RETURN: (for easy copy paste)

{rm_property_id,has_mls,has_tax,has_deed,street_address_num,street_address_name,street_address_unit,city,state,zip,geom_polys_raw,
geom_point_raw,geom_polys_json,geom_point_json,rm_status,close_date,owner_name,owner_name2_raw,owner_street_address_num,owner_street_address_name, etc..}
*/
CREATE OR REPLACE FUNCTION get_columns_array(tableName TEXT) RETURNS TABLE(cols name[]) AS $$
BEGIN
  RETURN QUERY EXECUTE 'SELECT ARRAY_AGG(cols) as cols from get_columns('''||tableName||''');';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION trim_left_right(l CHAR, r CHAR, _from TEXT) RETURNS TEXT AS $$
BEGIN
  l := '' || l || '';
  r := '' || r || '';
  RETURN trim(trailing r from trim(leading l from _from));
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_columns_array_text(tableName TEXT) RETURNS TABLE(cols text) AS $$
BEGIN
  RETURN QUERY EXECUTE 'SELECT trim_left_right(''{'',''}'',(cols::text)) as cols from get_columns_array('''||tableName||''');';
END;
$$ LANGUAGE plpgsql;

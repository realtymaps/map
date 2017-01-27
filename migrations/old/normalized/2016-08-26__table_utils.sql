DROP FUNCTION IF EXISTS for_all_tables_like(IN table_name_template TEXT, IN query_template TEXT);
CREATE OR REPLACE FUNCTION for_all_tables_like(IN table_name_template TEXT, IN query_template TEXT) RETURNS SETOF JSON
LANGUAGE plpgsql AS $$
  DECLARE row record;
  BEGIN
    FOR row IN
      SELECT
        table_schema,
        table_name
      FROM
        information_schema.tables
      WHERE
        table_type = 'BASE TABLE'
      AND
        table_schema = 'public'
      AND
        table_name ILIKE table_name_template
    LOOP
      RETURN QUERY EXECUTE 'SELECT row_to_json(x) FROM (' || replace(query_template, ' @ ', ' '||quote_ident(row.table_name)||' ') || ') AS x';
    END LOOP;
    RETURN;
  END;
$$;


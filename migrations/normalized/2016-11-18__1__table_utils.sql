DROP FUNCTION IF EXISTS for_all_tables_like_do(IN table_name_template TEXT, IN query_template TEXT);
CREATE OR REPLACE FUNCTION for_all_tables_like_do(IN table_name_template TEXT, IN query_template TEXT) RETURNS VOID
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
      EXECUTE replace(query_template, ' @ ', ' '||quote_ident(row.table_name)||' ');
    END LOOP;
    RETURN;
  END;
$$;

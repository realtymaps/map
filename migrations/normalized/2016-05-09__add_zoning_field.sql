 deed ADD COLUMN zoning TEXT;


CREATE OR REPLACE FUNCTION add_column_to_tables_like(IN _table_template TEXT, IN _column TEXT, IN _type TEXT, IN _value TEXT) RETURNS void
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
        table_name ILIKE _table_template
    LOOP
      EXECUTE 'ALTER TABLE public.' || quote_ident(row.table_name) || ' ADD COLUMN ' || quote_ident(_column) || ' ' || _type;
      EXECUTE 'UPDATE TABLE public.' || quote_ident(row.table_name) || ' SET ' || quote_ident(_column) || ' = ' || _value;
      RAISE INFO 'Altered table: %', quote_ident(row.table_name);
    END LOOP;
  END;
$$;

SELECT add_column_to_tables_like('deed_%', 'zoning', '');

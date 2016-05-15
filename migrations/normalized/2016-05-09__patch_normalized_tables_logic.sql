

-- not using this function now, but I want to waste the thought that went into this, so here it is for later use

CREATE OR REPLACE FUNCTION add_column_to_tables_like(IN _table_template TEXT, IN _column TEXT, IN _type TEXT, IN _value_predicates TEXT[][]) RETURNS void
LANGUAGE plpgsql AS $$
  DECLARE
    row record;
    predicate TEXT[2];
  BEGIN
    -- NOTE: ensure tasks which could be reading or writing the tables altered by this function are disabled while this runs
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
      FOREACH predicate IN ARRAY _value_predicates LOOP
        EXECUTE 'UPDATE TABLE public.' || quote_ident(row.table_name) || ' SET ' || quote_ident(_column) || ' = ' || predicate[1] || ' WHERE ' || predicate[0];
      END LOOP;
      RAISE INFO 'Altered table: %', quote_ident(row.table_name);
    END LOOP;
  END;
$$;

--SELECT add_column_to_tables_like('deed_%', 'zoning', '{
--  {"data_source_id = ''blackknight''", "<json operators to get the value from a non-base location>"}
--}');

DROP FUNCTION IF EXISTS drop_all_tables_like(IN _parttionbase TEXT);
CREATE OR REPLACE FUNCTION drop_all_tables_like(IN table_name_template TEXT) RETURNS SETOF TEXT
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
      EXECUTE 'DROP TABLE public.' || quote_ident(row.table_name);
      RETURN NEXT row.table_name;
    END LOOP;
    RETURN;
  END;
$$;


CREATE OR REPLACE FUNCTION inspect_indexes(IN table_name_template TEXT)
  RETURNS TABLE (table_name TEXT, index_name TEXT, column_names TEXT[])
LANGUAGE plpgsql AS $$
  BEGIN
    RETURN QUERY
    SELECT
      index_info.table_name,
      index_info.index_name,
      index_info.column_names
    FROM (
      SELECT
        column_info.table_name,
        column_info.index_name,
        array_agg(column_info.column_name) AS column_names
      FROM (
        SELECT
          t.relname::TEXT AS table_name,
          i.relname::TEXT AS index_name,
          a.attname::TEXT AS column_name
        FROM
          pg_class t,
          pg_class i,
          pg_index ix,
          pg_attribute a,
          pg_tables s
        WHERE
          t.oid = ix.indrelid
          AND i.oid = ix.indexrelid
          AND a.attrelid = t.oid
          AND a.attnum = ANY (ix.indkey)
          AND t.relkind = 'r'
          AND t.relname = s.tablename
          AND s.schemaname = 'public'
          AND t.relname ILIKE table_name_template
        ORDER BY
          t.relname,
          i.relname,
          a.attname
      ) AS column_info
      GROUP BY
        column_info.table_name,
        column_info.index_name
    ) AS index_info
    ORDER BY
      index_info.table_name,
      index_info.index_name;
  END;
$$;

CREATE OR REPLACE FUNCTION find_possible_dupe_indexes(IN table_name_template TEXT)
  RETURNS TABLE (table_name TEXT, index_names TEXT[], column_names TEXT[])
LANGUAGE plpgsql AS $$
  BEGIN
    RETURN QUERY
    SELECT * FROM (
      SELECT
        index_info.table_name,
        array_agg(index_info.index_name) AS index_names,
        index_info.column_names
      FROM inspect_indexes(table_name_template) AS index_info
      GROUP BY
        index_info.table_name,
        index_info.column_names
    ) AS dupe_info
    WHERE array_length(dupe_info.index_names, 1) > 1;
  END;
$$;

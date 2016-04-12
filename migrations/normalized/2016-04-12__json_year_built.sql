CREATE OR REPLACE FUNCTION drop_all_tables_like(IN _parttionbase TEXT) RETURNS void
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
        table_name ILIKE _parttionbase
    LOOP
      EXECUTE 'DROP TABLE public.' || quote_ident(row.table_name);
      RAISE INFO 'Dropped table: %', quote_ident(row.table_name);
    END LOOP;
  END;
$$;

SELECT drop_all_tables_like('deed_%');
SELECT drop_all_tables_like('mortgage_%');
SELECT drop_all_tables_like('tax_%');


TRUNCATE TABLE listing;
ALTER TABLE listing ALTER COLUMN year_built TYPE JSON USING NULL;

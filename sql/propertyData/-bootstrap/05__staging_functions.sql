CREATE OR REPLACE FUNCTION
  dirty_materialized_view(id TEXT, breaking BOOLEAN) RETURNS VOID AS
  $$
  BEGIN
    UPDATE view_status
    SET
      dirty = TRUE,
      dirty_breaking = dirty_breaking OR breaking
    WHERE view_id = id;
    
    INSERT INTO view_status (view_id, dirty, dirty_breaking)
    SELECT id, TRUE, breaking
    WHERE NOT EXISTS (
      SELECT view_id
      FROM view_status
      WHERE view_id = id
    );
  END;
  $$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  build_index_statements(id TEXT) RETURNS TEXT ARRAY AS
  $$
  DECLARE
    row view_definitions%ROWTYPE;
    partials TEXT ARRAY;
  BEGIN
    partials := '{}';
    FOR row IN SELECT * FROM view_definitions
    WHERE view_id = id AND clause_type = 'INDEX'
    ORDER BY ordering
    LOOP
      partials := partials || (
        'CREATE INDEX ' || ignore_blank('', row.name, ' ') || 
        'ON tmp_mv_' || id || ' ' || 
        ignore_blank('USING ', row.aux, ' ') || 
        '(' || row.definition || ');');
    END LOOP;
    RETURN partials;
  END;
  $$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  stage_dirty_view_query(id TEXT) RETURNS TEXT AS
  $$
  DECLARE
    materialized_view_query TEXT;
  BEGIN
    materialized_view_query := 'DROP TABLE IF EXISTS tmp_mv_' || id || ';' || newline();
    materialized_view_query := materialized_view_query || 'CREATE TABLE tmp_mv_' || id || ' AS ' || build_view_query(id) || ';' || newline();
    materialized_view_query := materialized_view_query || array_to_string(build_index_statements(id), newline());
    RETURN materialized_view_query;
  END;
  $$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  stage_dirty_views() RETURNS VOID AS
  $$
  DECLARE
    row view_status%ROWTYPE;
  BEGIN
    FOR row IN SELECT * FROM view_status
    WHERE dirty = TRUE
    LOOP
      UPDATE view_status
      SET
        dirty = FALSE,
        dirty_breaking = FALSE,
        staged = TRUE,
        staged_breaking = staged_breaking OR row.dirty_breaking
      WHERE view_id = row.view_id;
      EXECUTE stage_dirty_view_query(row.view_id);
    END LOOP;
  END;
  $$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  push_staged_view_query(id TEXT) RETURNS TEXT AS
  $$
  DECLARE
    materialized_view_query TEXT;
  BEGIN
    materialized_view_query := 'DROP TABLE IF EXISTS mv_' || id || ';' || newline();
    materialized_view_query := materialized_view_query || 'ALTER TABLE tmp_mv_' || id || ' RENAME TO ' || 'mv_' || id || ';';
    RETURN materialized_view_query;
  END;
  $$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  push_staged_views(breaking BOOLEAN) RETURNS VOID AS
  $$
  DECLARE
    row view_status%ROWTYPE;
  BEGIN
    FOR row IN SELECT * FROM view_status
    WHERE staged = TRUE AND ((staged_breaking = FALSE) OR breaking)
    LOOP
      UPDATE view_status
      SET
        staged = FALSE,
        staged_breaking = FALSE
      WHERE view_id = row.view_id;
      EXECUTE push_staged_view_query(row.view_id);
    END LOOP;
  END;
  $$
LANGUAGE plpgsql;


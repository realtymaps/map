CREATE OR REPLACE FUNCTION geojson_query(tableName TEXT,columnName TEXT, limitVal TEXT) RETURNS TEXT AS
  $$
  DECLARE
    type1 Text;
    type2 Text;
    columns Text;
  BEGIN
    type1 := '''FeatureCollection''';
    type2 := '''Feature''';
    columnName := '' || columnName ||'';
    -- all columns except the one we are making a geometry
    columns := replace(get_columns_array_text('' || tableName || ''), columnName || ',', '');
    RETURN 'SELECT row_to_json(fc) FROM
        (
            SELECT
              ' || type1 || ' AS TYPE,
                array_to_json (ARRAY_AGG(f)) AS features
            FROM
                (
                    SELECT ' ||  type2  || ' AS TYPE, ' || columnName  || ' AS geometry,'
                    || columns || '
                    FROM ' || tableName || ' limit ' || limitVal || '
                ) AS f
        ) AS fc;';
  END;
  $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION geojson_query_exec(text,text,text) RETURNS TABLE(js json) AS
  $$
    BEGIN
      RETURN QUERY EXECUTE geojson_query('' || $1 ||'','' || $2 || '',''|| $3 ||'');
    END;
  $$
LANGUAGE plpgsql;

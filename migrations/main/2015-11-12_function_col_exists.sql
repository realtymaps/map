CREATE OR REPLACE function col_exists(_tbl regclass, _col  text) RETURNS BOOL AS $$
BEGIN

IF EXISTS (
   SELECT 1 FROM pg_attribute
   WHERE  attrelid = _tbl
   AND    attname = _col
   AND    NOT attisdropped) THEN
   RETURN TRUE;

ELSE
   RETURN FALSE;
END IF;

END
$$ LANGUAGE plpgsql;

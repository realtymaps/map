CREATE OR REPLACE function f_add_col(_tbl regclass, _col  text, _type regtype, OUT success bool)
    LANGUAGE plpgsql AS
$func$
BEGIN

IF EXISTS (
   SELECT 1 FROM pg_attribute
   WHERE  attrelid = _tbl
   AND    attname = _col
   AND    NOT attisdropped) THEN
   success := FALSE;

ELSE
   EXECUTE format('ALTER TABLE %s ADD COLUMN %I %s', _tbl, _col, _type);
   success := TRUE;
END IF;

END
$func$;

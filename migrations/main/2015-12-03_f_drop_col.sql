CREATE OR REPLACE function f_drop_col(_tbl regclass, _col  text, OUT success bool)
    LANGUAGE plpgsql AS
$func$
BEGIN

IF EXISTS (
  SELECT 1 FROM pg_attribute
  WHERE  attrelid = _tbl
  AND    attname = _col
  AND    NOT attisdropped) THEN
  EXECUTE format('ALTER TABLE %s DROP COLUMN %I', _tbl, _col);
  success := TRUE;

ELSE
  success := FALSE;

END IF;

END
$func$;

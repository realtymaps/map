CREATE OR REPLACE function f_add_default_col(_tbl regclass, _col  text, _type regtype, _default text, OUT success bool)
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
   EXECUTE format('ALTER TABLE %s ADD COLUMN %I %s NOT NULL DEFAULT %s', _tbl, _col, _type, _default);
   success := TRUE;
END IF;

END
$func$;

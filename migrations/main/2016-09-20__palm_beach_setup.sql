UPDATE lookup_mls
SET
  state = TRIM(BOTH FROM state),
  full_name = TRIM(BOTH FROM full_name),
  mls = TRIM(BOTH FROM mls);

UPDATE lookup_mls
SET mls = 'SEAK'
WHERE state = 'AK' AND full_name = 'Southeast Alaska Board of Realtors';


ALTER TABLE lookup_mls ADD COLUMN code TEXT;
UPDATE lookup_mls SET code = REGEXP_REPLACE(mls, '[^a-zA-Z0-9]', '', 'g');
UPDATE lookup_mls
SET code = mls||state
WHERE EXISTS (
  SELECT 1 FROM (
    SELECT mls, COUNT(*) AS total
    FROM lookup_mls
  ) AS x
  WHERE x.total > 1 AND x.mls = lookup_mls.mls
);
ALTER TABLE lookup_mls ALTER COLUMN code SET NOT NULL;

UPDATE lookup_mls
SET mls = 'SWFLMLS'
WHERE mls = 'swflmls';


CREATE UNIQUE INDEX unique_lookup_mls_code ON lookup_mls (code);

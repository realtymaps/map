ALTER TABLE temp_lookup_mls DROP CONSTRAINT temp_lookup_mls_mult_unique;

DROP TABLE temp_lookup_mls;

CREATE TABLE temp_lookup_mls (
  state_name varchar NOT NULL,
  full_name varchar NOT NULL,
	mls varchar,
  CONSTRAINT temp_lookup_mls_mult_unique UNIQUE (state_name, full_name, mls)
)
WITH (OIDS=FALSE);

BEGIN;

\COPY temp_lookup_mls FROM './sqlImports/StateMLSAcronym.tsv' WITH (FORMAT CSV, DELIMITER E'\t');

COMMIT;

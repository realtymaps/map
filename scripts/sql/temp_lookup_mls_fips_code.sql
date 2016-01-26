DROP TABLE IF EXISTS temp_lookup_mls_fips_code;

CREATE TABLE temp_lookup_mls_fips_code (
  mls varchar,
  county varchar,
	fips_code varchar
)
WITH (OIDS=FALSE);

\COPY temp_lookup_mls_fips_code (mls, county, fips_code) FROM './sqlImports/MLS_County_FIPS.tsv' WITH (FORMAT CSV, DELIMITER E'\t');

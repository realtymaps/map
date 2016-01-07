DROP TABLE IF EXISTS temp_lookup_county_adjacents_no_parent;

CREATE TABLE temp_lookup_county_adjacents_no_parent (
	id serial,
	name varchar,
	fips_code varchar,
	neighbor_name varchar,
  neighbor_fips_code varchar,
	PRIMARY KEY (id)
)
WITH (OIDS=FALSE);

-- latin1 deals with errors and spanish chars
\COPY temp_lookup_county_adjacents_no_parent (name, fips_code, neighbor_name, neighbor_fips_code) FROM PROGRAM 'curl http://www2.census.gov/geo/docs/reference/county_adjacency.txt' WITH (FORMAT CSV, DELIMITER E'\t', encoding 'latin1');

DROP TABLE IF EXISTS temp_lookup_county_adjacents;

CREATE TABLE temp_lookup_county_adjacents (
	id serial,
	parent_id int,
	parent_fips_code varchar,
	name varchar,
	fips_code varchar,
	neighbor_name varchar,
  neighbor_fips_code varchar,
	PRIMARY KEY (id)
)
WITH (OIDS=FALSE);

with child as(
SELECT id, (
	SELECT MAX(id) from (
		SELECT * FROM temp_lookup_county_adjacents_no_parent) as b where b. fips_code IS NOT NULL AND b.id <= temp_lookup_county_adjacents_no_parent.id
) as parent_id, name, neighbor_name, neighbor_fips_code, fips_code
from temp_lookup_county_adjacents_no_parent
)
INSERT INTO temp_lookup_county_adjacents
Select
	child.id,
	child.parent_id,
	parent.fips_code as parent_fips_code,
	child.name,
	child.fips_code,
	child.neighbor_name,
	child.neighbor_fips_code
from child
JOIN temp_lookup_county_adjacents_no_parent parent on parent.id = child.parent_id

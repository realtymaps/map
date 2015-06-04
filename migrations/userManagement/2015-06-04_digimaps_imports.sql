CREATE TABLE digimaps_imports (
	folder_name varchar NOT NULL,
	fips_codes json DEFAULT '[]'::json,
	created_at timestamp NOT NULL DEFAULT now(),
	errors json,
	rm_modified_time timestamp NOT NULL DEFAULT now_utc(),
	rm_inserted_time timestamp NOT NULL DEFAULT now_utc(),
	PRIMARY KEY ("folder_name")
)
WITH (OIDS=FALSE);


CREATE TRIGGER update_digimaps_imports_rm_modified_time BEFORE UPDATE ON digimaps_imports FOR EACH ROW EXECUTE PROCEDURE "update_rm_modified_time_column"();
COMMENT ON TRIGGER update_digimaps_imports_rm_modified_time ON digimaps_imports IS NULL;

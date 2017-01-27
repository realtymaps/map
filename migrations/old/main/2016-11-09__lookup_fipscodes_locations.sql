ALTER TABLE lookup_fips_codes
	ADD COLUMN rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc();

CREATE TRIGGER update_modified_time_lookup_fips_codes
BEFORE UPDATE ON lookup_fips_codes
FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

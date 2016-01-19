DROP TABLE IF EXISTS lookup_mls_fips_code;

CREATE TABLE lookup_mls_fips_code (
	id serial,
  mls varchar,
  county varchar,
	fips_code varchar,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
	PRIMARY KEY (id)
)
WITH (OIDS=FALSE);

CREATE TRIGGER update_modified_time_lookup_mls_fips_code
  BEFORE UPDATE ON lookup_mls_fips_code
  FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();
BEGIN;


INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Boone', '17007');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Bureau', '17011');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Cook', '17031');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'DeKalb', '17037');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'DuPage', '17043');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Ford', '17053');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Grundy', '17063');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Kane', '17089');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Kankakee', '17091');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Kendall', '17093');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Lake', '17097');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Livingston', '17105');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Marshall', '17123');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'McHenry', '17111');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Ogle', '17141');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Will', '17197');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Winnebago', '17201');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Jasper (IN)', '18073');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Lake (IN)', '18089');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'LaPorte (IN)', '18091');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Newton (IN)', '18111');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Porter (IN)', '18127');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Pulaski (IN)', '18131');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Starke (IN)', '18149');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'White (IN)', '18181');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Kenosha (WI)', '55059');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Racine (WI)', '55101');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('MRED', 'Walworth (WI)', '55127');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('GLVAR', 'Clark', '32002');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('GLVAR', 'Lincoln', '32107');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('GLVAR', 'Nye', '32023');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('GLVAR', 'White Pine', '32033');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('ARMLS', 'Maricopa', '4013');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('ARMLS', 'Pinal', '4021');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('ARMLS', 'Coconino', '4005');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('ARMLS', 'Yavapai', '4025');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('SWFMLS', 'Collier', '12021');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('SWFMLS', 'Lee ', '12071');
INSERT INTO lookup_mls_fips_code (mls, county, fips_code) VALUES ('SWFMLS', 'Hendry', '12051');


DROP TABLE IF EXISTS temp_lookup_mls_fips_code;

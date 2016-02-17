CREATE TABLE IF NOT EXISTS auth_m2m_user_locations (
  id serial,
  auth_user_id int4 NOT NULL,
  fips_code varchar(20) NOT NULL,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  CONSTRAINT auth_m2m_user_mls_auth_user_id_fk FOREIGN KEY (auth_user_id) REFERENCES auth_user (id) ON UPDATE CASCADE ON DELETE CASCADE,
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);

CREATE TABLE IF NOT EXISTS  auth_m2m_user_mls (
  id serial,
  mls_code VARCHAR(10) NOT NULL,
  auth_user_id int4 NOT NULL,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  CONSTRAINT auth_m2m_user_mls_auth_user_id_fk FOREIGN KEY (auth_user_id) REFERENCES auth_user (id) ON UPDATE CASCADE ON DELETE CASCADE,
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);

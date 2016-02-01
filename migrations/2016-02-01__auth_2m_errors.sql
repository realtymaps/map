CREATE TABLE auth_2m_errors (
  id serial,
  auth_user_id int4 NOT NULL,
  error_name varchar NOT NULL,
  data json NOT NULL,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  CONSTRAINT auth_2m_errors_auth_user_id_fk FOREIGN KEY ("auth_user_id") REFERENCES auth_user ("id") ON UPDATE CASCADE ON DELETE CASCADE,
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE,
)
WITH (OIDS=FALSE);

CREATE TRIGGER update_modified_time_auth_2m_errors
BEFORE UPDATE ON auth_2m_errors
FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

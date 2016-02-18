CREATE TABLE user_shell_history (
  id serial,
  auth_user_id int4 NOT NULL,
  executed_cmd varchar NOT NULL,
  error json,
  stdout varchar,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  CONSTRAINT user_shell_history_auth_user_id_fk FOREIGN KEY ("auth_user_id") REFERENCES auth_user ("id") ON UPDATE CASCADE ON DELETE CASCADE,
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);


CREATE TRIGGER update_modified_time_user_shell_history
BEFORE UPDATE ON user_shell_history
FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

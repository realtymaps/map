/*
Table to hold many possible errors to a auth_user.
Examples are stripe, verro or whatever errors.

auth_user_id is not a FK on purpose as an error transaction could have backed out a user to begin with. IE there could be
an error where something exist on stripe or vero where a user no longer exist here.

There for there would probabaly need to be a routine specifically to go through dead rows for dead users.
*/
CREATE TABLE auth_2m_errors (
  id serial,
  auth_user_id int4,
  error_name varchar NOT NULL,
  data json NOT NULL,
  attempt int4 NOT NULL,
  max_attempts int4 NOT NULL,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);

CREATE TRIGGER update_modified_time_auth_2m_errors
BEFORE UPDATE ON auth_2m_errors
FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

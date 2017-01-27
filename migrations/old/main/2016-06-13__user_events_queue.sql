CREATE TABLE user_events_queue (
  id serial,
  auth_user_id int4 NOT NULL,
  type text NOT NULL,
  options json,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  CONSTRAINT user_events_queue_auth_user_id_fk FOREIGN KEY (auth_user_id) REFERENCES auth_user (id) ON DELETE CASCADE,
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);

CREATE TABLE user_notification (
  id serial,
  config_notification_id int4 NOT NULL,
  options json NOT NULL DEFAULT '{}',
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  last_attempt_time TIMESTAMP WITHOUT TIME ZONE,
  attempts int,
  error text,
  CONSTRAINT user_notification_auth_user_id_fk FOREIGN KEY ("config_notification_id")
    REFERENCES config_notification ("id") ON UPDATE CASCADE ON DELETE CASCADE,
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);


CREATE TRIGGER update_modified_time_user_notification
BEFORE UPDATE ON user_notification
FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();


CREATE INDEX IF NOT EXISTS user_notification_config_notification_id_rm_inserted_time_last_attempt_time_error_idx
ON user_notification USING btree (config_notification_id, rm_inserted_time, last_attempt_time, error);

CREATE INDEX IF NOT EXISTS user_notification_rm_inserted_time_idx
ON user_notification USING btree (rm_inserted_time);

CREATE INDEX IF NOT EXISTS user_notification_attempts_idx
ON user_notification USING btree (attempts);

CREATE INDEX IF NOT EXISTS user_notification_error_idx
ON user_notification USING btree (error);

DROP table if exists config_notification;

CREATE TABLE config_notification (
  id serial,
  auth_user_id int4 NOT NULL,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  type text NOT NULL, -- pinned,  favorite, jobQueue,
  method text NOT NULL, -- email, emailVero, sms
  -- text enum in code or in db? immediate, ondemand (job queue) , daily, weekly
  frequency text NOT NULL,
  -- up (to parent_auth_user_id), down (to all children auth_user_id),
  -- all (to parent and all its children)
  bubble_direction text,
  max_attempts int,
  CONSTRAINT config_notification_auth_user_id_fk FOREIGN KEY ("auth_user_id")
    REFERENCES auth_user ("id") ON UPDATE CASCADE ON DELETE CASCADE,
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);


CREATE TRIGGER update_modified_time_config_notification
BEFORE UPDATE ON config_notification
FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();


CREATE INDEX IF NOT EXISTS config_notification_auth_user_id_method_type_frequency_idx
ON config_notification USING btree (auth_user_id, method, type, frequency);

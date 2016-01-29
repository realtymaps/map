CREATE TABLE error_queue (
  id serial,
  jq_task_name varchar(30) NOT NULL,
  data json NOT NULL,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE,
)
WITH (OIDS=FALSE);


CREATE TRIGGER update_modified_time_error_queue
BEFORE UPDATE ON error_queue
FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

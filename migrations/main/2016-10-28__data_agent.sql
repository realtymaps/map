DROP TABLE IF EXISTS data_agent;
CREATE TABLE data_agent (
  data_source_id TEXT NOT NULL,
  data_source_uuid TEXT NOT NULL,
  rm_raw_id INTEGER NOT NULL,

  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  up_to_date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  batch_id TEXT NOT NULL,
  inserted TEXT NOT NULL,
  updated TEXT,
  change_history JSON NOT NULL DEFAULT '[]'::JSON,

  active BOOLEAN NOT NULL,

  license_number INTEGER NOT NULL,
  agent_status TEXT NOT NULL,
  email TEXT,
  full_name TEXT NOT NULL,
  work_phone TEXT,
  ungrouped_fields JSON
);

DROP INDEX IF EXISTS data_agent_license_number_idx;
CREATE INDEX data_agent_data_source_id_idx ON data_agent USING btree (data_source_id);
CREATE INDEX data_agent_data_source_id_license_number_idx ON data_agent USING btree (data_source_id, license_number);
CREATE INDEX data_agent_data_source_id_data_source_uuid_idx ON data_agent USING btree (data_source_id, data_source_uuid) WHERE active IS FALSE;


DELETE FROM config_data_normalization WHERE data_type = 'agent';
INSERT INTO config_data_normalization ("data_source_id","list","output","ordering","required","input","transform","config","data_source_type","data_type")
VALUES
  (E'swflmls',E'base',E'agent_status',2,TRUE,E'"Agent Status"',NULL,E'{"nullEmpty":true,"trim":true,"mapping":{"Active":"active","Inactive":"inactive"}}',E'mls',E'agent'),
  (E'swflmls',E'base',E'data_source_uuid',5,TRUE,E'"Matrix Unique ID"',NULL,E'{"nullEmpty":true,"trim":true}',E'mls',E'agent'),
  (E'swflmls',E'base',E'email',3,FALSE,E'"Email"',NULL,E'{"nullEmpty":true,"trim":true}',E'mls',E'agent'),
  (E'swflmls',E'base',E'full_name',1,TRUE,E'{"full":"Full Name","first":"First Name","middle":"Middle Name","last":"Last Name","suffix":"Generational Name"}',NULL,E'{}',E'mls',E'agent'),
  (E'swflmls',E'base',E'license_number',0,TRUE,E'"License Number"',NULL,E'{"nullEmpty":true,"trim":true}',E'mls',E'agent'),
  (E'swflmls',E'base',E'work_phone',4,FALSE,E'"Direct Work Phone"',NULL,E'{"nullEmpty":true,"trim":true}',E'mls',E'agent');

DROP TABLE IF EXISTS agent;
CREATE TABLE agent (
  data_source_id TEXT NOT NULL,
  data_source_uuid TEXT NOT NULL,
  rm_raw_id INTEGER NOT NULL,

  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  up_to_date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  batch_id TEXT NOT NULL,
  inserted TEXT NOT NULL,
  updated TEXT,
  deleted TEXT,
  change_history JSON NOT NULL DEFAULT '[]'::JSON,

  active BOOLEAN NOT NULL,

  license_number INTEGER NOT NULL,
  agent_status TEXT NOT NULL,
  email TEXT,
  full_name TEXT NOT NULL,
  work_phone TEXT,
  ungrouped_fields JSON
);

DROP INDEX IF EXISTS agent_license_number_idx;
CREATE INDEX agent_data_source_id_idx ON agent USING btree (data_source_id);
CREATE INDEX agent_data_source_id_license_number_idx ON agent USING btree (data_source_id, license_number);
CREATE INDEX agent_data_source_id_data_source_uuid_idx ON agent USING btree (data_source_id, data_source_uuid) WHERE active IS FALSE;

CREATE TRIGGER update_modified_time_agent
BEFORE UPDATE ON agent
FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

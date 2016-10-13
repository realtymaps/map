CREATE TABLE data_agent (
  license_number INTEGER NOT NULL,
  status TEXT NOT NULL,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  work_phone TEXT,
  data_source_id TEXT,
  up_to_date TIMESTAMP WITHOUT TIME ZONE,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  batch_id TEXT,
  active BOOLEAN NOT NULL
);

DROP INDEX IF EXISTS data_agent_license_number_idx;
CREATE INDEX data_agent_license_number_idx ON data_agent USING btree (license_number);

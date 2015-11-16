DROP TABLE IF EXISTS data_normal_mortgage;
CREATE TABLE data_normal_mortgage (
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  
  data_source_id TEXT NOT NULL,
  batch_id TEXT NOT NULL,
  deleted TEXT,
  up_to_date TIMESTAMP NOT NULL,
  
  change_history JSON NOT NULL DEFAULT '[]',
  
  data_source_uuid TEXT NOT NULL,
  rm_property_id TEXT NOT NULL,
  fips_code INTEGER NOT NULL,
  parcel_id TEXT NOT NULL,
  address JSON NOT NULL,
  close_date TIMESTAMP,
  
  rm_raw_id INTEGER NOT NULL,
  inserted TEXT NOT NULL,
  updated TEXT,
  
  client_groups JSON NOT NULL,
  realtor_groups JSON NOT NULL,
  hidden_fields JSON NOT NULL,
  ungrouped_fields JSON
);

CREATE TRIGGER update_modified_time_data_normal_mortgage
  BEFORE UPDATE ON data_normal_mortgage
  FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

CREATE UNIQUE INDEX ON data_normal_mortgage (data_source_id, data_source_uuid);
CREATE INDEX ON data_normal_mortgage (batch_id);
CREATE INDEX ON data_normal_mortgage (rm_property_id, deleted, close_date DESC NULLS FIRST);


-- also a tiny bit of cleanup, have a duplicate index on data_normal_deed
DROP INDEX IF EXISTS normal_deed_data_rm_property_id_deleted_close_date_idx1;

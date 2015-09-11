DROP TABLE IF EXISTS normal_tax_data;
CREATE TABLE normal_tax_data (
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
  price NUMERIC,
  close_date TIMESTAMP,
  bedrooms INTEGER,
  baths_full INTEGER,
  acres NUMERIC,
  sqft_finished INTEGER,
  owner_name TEXT,
  owner_name_2 TEXT,

  rm_raw_id INTEGER NOT NULL,
  inserted TEXT NOT NULL,
  updated TEXT,
  
  client_groups JSON NOT NULL,
  realtor_groups JSON NOT NULL,
  hidden_fields JSON NOT NULL,
  ungrouped_fields JSON
);

CREATE TRIGGER update_modified_time_normal_tax_data
  BEFORE UPDATE ON normal_tax_data
  FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

CREATE UNIQUE INDEX ON normal_tax_data (data_source_id, data_source_uuid);
CREATE INDEX ON normal_tax_data (rm_property_id, deleted, close_date DESC NULLS FIRST);

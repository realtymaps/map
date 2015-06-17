DROP TABLE IF EXISTS combined_data;
CREATE TABLE combined_data (
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),

  data_source_id TEXT NOT NULL,
  data_source_type TEXT NOT NULL,
  batch_id TEXT NOT NULL,
  up_to_date TIMESTAMP NOT NULL,
  active BOOLEAN NOT NULL,

  change_history JSON,
  prior_listings JSON,

  rm_property_id TEXT NOT NULL,
  fips_code INTEGER NOT NULL,
  parcel_id TEXT NOT NULL,
  address JSON NOT NULL,
  price NUMERIC,
  close_date TIMESTAMP,
  days_on_market INTEGER,
  bedrooms INTEGER,
  baths_full INTEGER,
  acres NUMERIC,
  sqft_finished INTEGER,
  status TEXT,
  substatus TEXT,
  status_display TEXT,

  owner_name TEXT,
  owner_name_2 TEXT,

  geometry JSON,
  geometry_center JSON,
  geometry_raw GEOMETRY(MultiPolygon,26910),

  client_groups JSON NOT NULL,
  realtor_groups JSON NOT NULL,
  hidden_fields JSON NOT NULL,
  ungrouped_fields JSON NOT NULL
);

CREATE TRIGGER update_modified_time_combined_data
AFTER UPDATE ON combined_data
FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

CREATE INDEX ON combined_data USING GIST (geometry_raw);
CREATE INDEX ON combined_data (rm_property_id);
CREATE INDEX ON combined_data (price);
CREATE INDEX ON combined_data (close_date);
CREATE INDEX ON combined_data (days_on_market);
CREATE INDEX ON combined_data (bedrooms);
CREATE INDEX ON combined_data (baths_full);
CREATE INDEX ON combined_data (acres);
CREATE INDEX ON combined_data (sqft_finished);
CREATE INDEX ON combined_data (status);
CREATE INDEX ON combined_data (owner_name);
CREATE INDEX ON combined_data (owner_name_2);
CREATE INDEX ON combined_data (active);
CREATE INDEX ON combined_data (data_source_type);
CREATE INDEX ON combined_data (data_source_id);

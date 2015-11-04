
CREATE TABLE IF NOT EXISTS combined_data_deletes (
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_property_id TEXT NOT NULL,
  data_source_id TEXT NOT NULL,
  batch_id TEXT NOT NULL
);

CREATE INDEX ON combined_data_deletes (data_source_id, batch_id, rm_property_id);

DROP TABLE IF EXISTS data_load_history;
CREATE TABLE data_load_history (
  data_source_id TEXT NOT NULL,
  data_source_type TEXT NOT NULL,
  batch_id TEXT NOT NULL,
  raw_table_name TEXT NOT NULL,
  valid_rows INTEGER,
  invalid_rows INTEGER
);

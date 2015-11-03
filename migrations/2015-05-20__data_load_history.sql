ALTER TABLE data_load_history ADD COLUMN rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc();

ALTER TABLE mls_data ADD COLUMN mls_uuid TEXT NOT NULL;

CREATE UNIQUE INDEX ON mls_data (data_source_id, mls_uuid);

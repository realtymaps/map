
ALTER TABLE combined_data ADD COLUMN update_source TEXT;
UPDATE combined_data set update_source = data_source_id;
ALTER TABLE combined_data ALTER COLUMN update_source SET NOT NULL;

CREATE INDEX ON combined_data (data_source_id, rm_property_id, update_source, batch_id)
  WHERE active = FALSE;

CREATE INDEX ON combined_data (data_source_id);

DROP INDEX IF EXISTS combined_data_active_data_source_id_idx;

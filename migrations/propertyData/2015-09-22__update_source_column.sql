
ALTER combined_data ADD COLUMN update_source TEXT NOT NULL USING data_source_id;
CREATE INDEX ON combined_data (data_source_id, rm_property_id, update_source, batch_id)
  WHERE active = FALSE;

CREATE INDEX ON combined_data (data_source_id);

DROP INDEX IF EXISTS combined_data_active_data_source_id_idx;

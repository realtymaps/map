ALTER TABLE data_combined DROP COLUMN photo_import_error;

CREATE TABLE retry_photos (
  data_source_id TEXT NOT NULL,
  data_source_uuid TEXT NOT NULL,
  batch_id TEXT NOT NULL,
  error TEXT NOT NULL
);
CREATE UNIQUE INDEX retry_photos_unique ON retry_photos (data_source_id, data_source_uuid, batch_id);

UPDATE jq_subtask_config SET auto_enqueue = TRUE
WHERE name LIKE '%_storePhotosPrep';

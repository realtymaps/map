ALTER TABLE data_combined add column actual_photo_count int NOT NULL DEFAULT 0;

UPDATE data_combined
  set actual_photo_count=(select count(keys) - 1 from jsonb_object_keys(data_combined.photos) keys)
WHERE photos != '{}';

ALTER TABLE data_combined add column actual_photo_count int NOT NULL DEFAULT 0;

CREATE OR REPLACE FUNCTION update_actual_photo_count()
  RETURNS TRIGGER AS $$
BEGIN
  NEW.actual_photo_count=count(keys) - 1 from jsonb_object_keys(NEW.photos) keys;
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

UPDATE data_combined
  set actual_photo_count=(select count(keys) - 1 from jsonb_object_keys(data_combined.photos) keys)
WHERE photos != '{}';

CREATE TRIGGER update_actual_photo_count_trigger
BEFORE UPDATE ON data_combined
FOR EACH ROW EXECUTE PROCEDURE update_actual_photo_count();

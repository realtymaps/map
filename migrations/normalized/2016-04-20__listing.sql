ALTER TABLE listing add column actual_photo_count int NOT NULL DEFAULT 0;
ALTER TABLE listing add column cdn_photo text NOT NULL DEFAULT '';

CREATE OR REPLACE FUNCTION update_actual_photo_count()
  RETURNS TRIGGER AS $$
BEGIN
  NEW.actual_photo_count=count(keys) - 1 from jsonb_object_keys(NEW.photos) keys;
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

UPDATE listing
  set actual_photo_count=(select count(keys) - 1 from jsonb_object_keys(listing.photos) keys)
WHERE photos != '{}';

CREATE TRIGGER update_actual_photo_count_listing_trigger
BEFORE UPDATE ON listing
FOR EACH ROW EXECUTE PROCEDURE update_actual_photo_count();

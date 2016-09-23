ALTER TABLE retry_photos ADD COLUMN photo_id TEXT;

-- need to set the values here

ALTER TABLE retry_photos ALTER COLUMN photo_id SET NOT NULL;

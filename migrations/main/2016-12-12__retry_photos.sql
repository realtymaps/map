DELETE FROM retry_photos;
ALTER TABLE retry_photos ADD COLUMN photo_count int4 NOT NULL;

ALTER TABLE retry_photos ADD COLUMN retries INTEGER DEFAULT 0;

DROP INDEX IF EXISTS retry_photos_unique;
CREATE UNIQUE INDEX retry_photos_unique ON retry_photos USING btree (data_source_id, data_source_uuid);

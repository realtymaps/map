ALTER TABLE parcel DROP COLUMN IF EXISTS data_source_id;
ALTER TABLE parcel RENAME TO parcel_digimaps;

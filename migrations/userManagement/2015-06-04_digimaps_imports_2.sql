ALTER TABLE digimaps_imports RENAME TO digimaps_parcel_imports;
ALTER TABLE digimaps_parcel_imports DROP COLUMN created_at;
ALTER TABLE digimaps_parcel_imports ADD COLUMN imported_time timestamp NULL;
ALTER TABLE digimaps_parcel_imports ADD COLUMN full_path varchar NOT NULL;

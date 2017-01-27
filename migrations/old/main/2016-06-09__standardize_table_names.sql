ALTER TABLE parcel RENAME TO data_parcel;
ALTER TABLE data_combined_deletes RENAME TO deletes_combined;
ALTER TABLE parcel_deletes RENAME TO deletes_parcel;
ALTER TABLE delete_photos RENAME TO deletes_photos;

DROP TRIGGER update_modified_time_delete_photos ON deletes_photos;
TRUNCATE TABLE deletes_photos;
ALTER TABLE deletes_photos DROP COLUMN rm_modified_time;
ALTER TABLE deletes_photos DROP COLUMN id;

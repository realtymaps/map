
DELETE FROM data_parcel WHERE active = FALSE;
ALTER TABLE data_parcel DROP COLUMN active;

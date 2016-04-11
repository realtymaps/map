DROP INDEX parcel_change_history_idx;
DROP INDEX parcel_prior_entries_idx;

ALTER TABLE parcel
	ALTER COLUMN change_history TYPE json,
	ALTER COLUMN prior_entries TYPE json;

ALTER TABLE parcel ADD COLUMN update_source text NOT NULL DEFAULT 'mv_parcels';
ALTER TABLE parcel ALTER COLUMN update_source DROP DEFAULT;

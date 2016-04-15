DROP INDEX parcel_change_history_idx;
ALTER TABLE parcel ALTER COLUMN change_history TYPE json;

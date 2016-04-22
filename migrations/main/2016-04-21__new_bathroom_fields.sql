
ALTER TABLE data_combined DROP COLUMN baths_full;
ALTER TABLE data_combined ADD COLUMN baths JSON;
ALTER TABLE data_combined ADD COLUMN baths_total NUMERIC(4, 1);

DELETE FROM config_data_normalization WHERE output IN ('baths_full', 'baths_half', 'baths_total');

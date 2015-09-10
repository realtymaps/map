
-- use more general names and constraints, so they can apply to county data as well as MLS

ALTER TABLE mls_data RENAME TO normal_listing_data;
ALTER TABLE normal_listing_data RENAME COLUMN mls_uuid TO data_source_uuid;
ALTER TABLE combined_data RENAME COLUMN mls_uuid TO data_source_uuid;
ALTER TABLE combined_data RENAME COLUMN prior_listings TO prior_entries;

UPDATE data_normalization_config
SET output = 'data_source_uuid'
WHERE output = 'mls_uuid';

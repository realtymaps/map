
-- use more general names, so they apply to county data as well as MLS

ALTER TABLE mls_data RENAME COLUMN client_groups TO shared_groups;
ALTER TABLE mls_data RENAME COLUMN realtor_groups TO subscriber_groups;

ALTER TABLE combined_data RENAME COLUMN client_groups TO shared_groups;
ALTER TABLE combined_data RENAME COLUMN realtor_groups TO subscriber_groups;

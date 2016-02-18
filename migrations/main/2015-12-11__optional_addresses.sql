ALTER TABLE data_normal_deed ALTER COLUMN address DROP NOT NULL;
ALTER TABLE data_normal_tax ALTER COLUMN address DROP NOT NULL;
ALTER TABLE data_normal_mortgage ALTER COLUMN address DROP NOT NULL;
ALTER TABLE data_normal_listing ALTER COLUMN address DROP NOT NULL;
ALTER TABLE data_combined ALTER COLUMN address DROP NOT NULL;

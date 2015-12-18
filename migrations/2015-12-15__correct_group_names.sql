ALTER TABLE data_normal_deed RENAME COLUMN realtor_groups TO subscriber_groups;
ALTER TABLE data_normal_deed RENAME COLUMN client_groups TO shared_groups;
ALTER TABLE data_normal_tax RENAME COLUMN realtor_groups TO subscriber_groups;
ALTER TABLE data_normal_tax RENAME COLUMN client_groups TO shared_groups;
ALTER TABLE data_normal_mortgage RENAME COLUMN realtor_groups TO subscriber_groups;
ALTER TABLE data_normal_mortgage RENAME COLUMN client_groups TO shared_groups;

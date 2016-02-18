ALTER TABLE data_normal_deed ADD COLUMN owner_address JSON;
ALTER TABLE data_normal_mortgage ADD COLUMN owner_address JSON;
ALTER TABLE data_normal_tax ADD COLUMN owner_address JSON;
ALTER TABLE data_combined ADD COLUMN owner_address JSON;


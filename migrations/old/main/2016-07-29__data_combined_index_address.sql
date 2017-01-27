ALTER TABLE data_combined ALTER COLUMN address TYPE jsonb;

CREATE INDEX data_combined_address_idx ON data_combined USING gin (address) WHERE active IS TRUE;

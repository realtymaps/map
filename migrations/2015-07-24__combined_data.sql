-- need these fields in combined_data too
ALTER TABLE combined_data ADD COLUMN discontinued_date TIMESTAMP;
ALTER TABLE combined_data ADD COLUMN rm_raw_id INTEGER NOT NULL;
ALTER TABLE combined_data ADD COLUMN mls_uuid TEXT NOT NULL;

-- want empty ungrouped_fields to be null for easier queries
ALTER TABLE combined_data ALTER COLUMN ungrouped_fields DROP NOT NULL;

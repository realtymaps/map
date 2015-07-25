-- want empty ungrouped_fields to be null for easier queries
ALTER TABLE mls_data ALTER COLUMN ungrouped_fields DROP NOT NULL;

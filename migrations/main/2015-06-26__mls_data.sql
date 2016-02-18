-- need close date for advanced "sold" searching
ALTER TABLE mls_data ADD COLUMN discontinued_date TIMESTAMP;

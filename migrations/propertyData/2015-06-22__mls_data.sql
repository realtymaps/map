-- need close date for advanced "sold" searching
ALTER TABLE mls_data ADD COLUMN hide_listing BOOLEAN NOT NULL;

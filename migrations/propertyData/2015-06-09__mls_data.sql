-- deleted rows will now have a batch_id here instead of TRUE, and NULL instead of FALSE
ALTER TABLE mls_data ALTER COLUMN deleted DROP NOT NULL;
ALTER TABLE mls_data ALTER COLUMN deleted TYPE TEXT USING NULL;

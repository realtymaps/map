-- track the batch_id of insert and update just like delete
ALTER TABLE combined_data ADD COLUMN inserted TEXT NOT NULL DEFAULT 'invalid';
ALTER TABLE combined_data ADD COLUMN updated TEXT;
ALTER TABLE combined_data ALTER COLUMN change_history SET DEFAULT '[]';
UPDATE combined_data SET change_history = '[]' WHERE change_history IS NULL;
ALTER TABLE combined_data ALTER COLUMN change_history SET NOT NULL;

ALTER TABLE mls_data ADD COLUMN inserted TEXT NOT NULL DEFAULT 'invalid';
ALTER TABLE mls_data ADD COLUMN updated TEXT;
ALTER TABLE mls_data ALTER COLUMN change_history SET DEFAULT '[]';
UPDATE mls_data SET change_history = '[]' WHERE change_history IS NULL;
ALTER TABLE mls_data ALTER COLUMN change_history SET NOT NULL;

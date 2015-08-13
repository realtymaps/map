-- track the batch_id of insert and update just like delete
ALTER TABLE combined_data ADD COLUMN inserted TEXT NOT NULL DEFAULT 'invalid';
ALTER TABLE combined_data ADD COLUMN updated TEXT;
ALTER TABLE combined_data ALTER COLUMN change_history SET DEFAULT '[]';
ALTER TABLE combined_data ALTER COLUMN change_history SET NOT NULL;

ALTER TABLE mls_data ADD COLUMN inserted TEXT NOT NULL DEFAULT 'invalid';
ALTER TABLE mls_data ADD COLUMN updated TEXT;
ALTER TABLE mls_data ALTER COLUMN change_history SET DEFAULT '[]';
ALTER TABLE mls_data ALTER COLUMN change_history SET NOT NULL;

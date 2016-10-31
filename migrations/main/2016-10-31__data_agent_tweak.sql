ALTER TABLE data_agent ALTER COLUMN license_number DROP NOT NULL;
ALTER TABLE data_agent ALTER COLUMN license_number TYPE TEXT;

ALTER TABLE config_mls ADD COLUMN agent_data jsonb NOT NULL DEFAULT '{}';
ALTER TABLE config_mls ALTER COLUMN agent_data DROP DEFAULT;

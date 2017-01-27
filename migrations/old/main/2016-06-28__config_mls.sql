ALTER TABLE config_mls ADD COLUMN verify_overlap BOOLEAN NOT NULL DEFAULT TRUE;

UPDATE config_mls
SET verify_overlap = FALSE
WHERE id = 'MRED';

ALTER TABLE session_security ADD COLUMN app TEXT NOT NULL DEFAULT 'map';

ALTER TABLE session_security RENAME COLUMN next_security_token TO token;

ALTER TABLE session_security
  DROP COLUMN IF EXISTS current_security_token,
  DROP COLUMN IF EXISTS previous_security_token,
  ALTER COLUMN app DROP DEFAULT;

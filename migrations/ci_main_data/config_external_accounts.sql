-------------------------------------------------------------------------------
-- this file should contain UNENCRYPTED, FAKE values only.
-- DO NOT commit encrypted and/or real values to the VCS, here or elsewhere
-------------------------------------------------------------------------------

INSERT INTO config_external_accounts
  (name, username, password, api_key, other, url, environment)
VALUES
  ('twilio', 'rmaps_username', 'rmaps_password', 'rmaps_API_KEY', '{"number":"+1-234-567-8910"}', 'rmaps_', NULL);

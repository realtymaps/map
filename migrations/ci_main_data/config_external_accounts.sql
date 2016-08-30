-------------------------------------------------------------------------------
-- this file should contain UNENCRYPTED, FAKE values only.
-- DO NOT commit encrypted and/or real values to the VCS, here or elsewhere
-------------------------------------------------------------------------------

INSERT INTO config_external_accounts
  (name, username, password, api_key, other, url, environment)
VALUES
  ('twilio', 'rmaps_username', 'rmaps_password', 'rmaps_API_KEY', '{"number":"+1-234-567-8910"}', 'rmaps_', NULL);

insert into config_external_accounts (name, other, api_key)
values ('vero', '{
"auth_token":"crap1",
"secret_api_key":"crap2",
"public_api_key":"crap3"
}', 'crap4');

insert into config_external_accounts ( "name", "username", "password", "api_key", "other", "url", "environment")
  values (
    'cartodb', 'junk', null, 'api_key', '{"api_key_to_us":"api_key_to_us","map-parcels":"map-parcels","map-parcelsAddresses":"map-parcelsAddresses"}'
    , null, null);


insert into config_external_accounts ( name, api_key, other)
values ( 'stripe', 'rmaps_API_KEY', '{
"secret_test_api_key":"rmaps_API_KEY_SECRET",
"public_test_api_key":"rmaps_API_KEY_PUBLIC",
"secret_live_api_key":"rmaps_API_KEY_SECRET_LIVE",
"public_live_api_key":"rmaps_API_KEY_PUBLIC_LIVE"
}');

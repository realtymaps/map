-- setting verified mls's for superuser accounts so that created subusers via those accounts will have correct perms

UPDATE auth_user
SET mlses_verified = '["swflmls"]' -- NOTE: corresponds to `config_mls.id`, NOT `lookup_mls.mls` since that's what `data_combined` uses
WHERE is_superuser = true OR first_name = 'Dan';

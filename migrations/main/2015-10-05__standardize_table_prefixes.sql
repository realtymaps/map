
-- view that isn't needed any more, replaced with knex code
DROP VIEW IF EXISTS jq_data_health;

-- standardizing table names so they're grouped logically (when sorted alphabetically)
ALTER TABLE IF EXISTS session RENAME TO auth_session;
ALTER TABLE IF EXISTS session_security RENAME TO auth_session_security;
ALTER TABLE IF EXISTS auth_user_user_permissions RENAME TO auth_m2m_user_permissions;
ALTER TABLE IF EXISTS auth_user_groups RENAME TO auth_m2m_user_groups;
ALTER TABLE IF EXISTS auth_group_permissions RENAME TO auth_m2m_group_permissions;
ALTER TABLE IF EXISTS auth_user_profile RENAME TO user_profile;
ALTER TABLE IF EXISTS project RENAME TO user_project;
ALTER TABLE IF EXISTS company RENAME TO user_company;
ALTER TABLE IF EXISTS account_images RENAME TO user_account_images;
ALTER TABLE IF EXISTS data_load_history RENAME TO jq_data_load_history;
ALTER TABLE IF EXISTS fips_lookup RENAME TO lookup_fips_codes;
ALTER TABLE IF EXISTS account_use_types RENAME TO lookup_account_use_types;
ALTER TABLE IF EXISTS us_states RENAME TO lookup_us_states;
ALTER TABLE IF EXISTS data_normalization_config RENAME TO config_data_normalization;
ALTER TABLE IF EXISTS keystore RENAME TO config_keystore;
ALTER TABLE IF EXISTS external_accounts RENAME TO config_external_accounts;
ALTER TABLE IF EXISTS notification RENAME TO config_notification;
ALTER TABLE IF EXISTS mls_config RENAME TO config_mls;
ALTER TABLE IF EXISTS normal_listing_data RENAME TO data_normal_listing;
ALTER TABLE IF EXISTS normal_tax_data RENAME TO data_normal_tax;
ALTER TABLE IF EXISTS normal_deed_data RENAME TO data_normal_deed;
ALTER TABLE IF EXISTS combined_data RENAME TO data_combined;
ALTER TABLE IF EXISTS combined_data_deletes RENAME TO data_combined_deletes;

-- this is an old remnant of having a completely separate admin app
ALTER TABLE auth_session_security DROP COLUMN IF EXISTS app;

-- remnant of stuff from the django app
DROP TABLE IF EXISTS management_useraccountprofile;

-- new tables
ALTER TABLE IF EXISTS data_source_fields RENAME TO config_data_source_fields;
ALTER TABLE IF EXISTS data_source_lookups RENAME TO config_data_source_lookups;
ALTER TABLE IF EXISTS notes RENAME TO user_notes;

DROP VIEW IF EXISTS jq_summary;

ALTER TABLE session RENAME TO auth_session;
ALTER TABLE session_security RENAME TO auth_session_security;
ALTER TABLE auth_user_user_permissions RENAME TO auth_m2m_user_permissions;
ALTER TABLE auth_user_groups RENAME TO auth_m2m_user_groups;
ALTER TABLE auth_group_permissions RENAME TO auth_m2m_group_permissions;
ALTER TABLE auth_user_profile RENAME TO user_profile;
ALTER TABLE project RENAME TO user_project;
ALTER TABLE company RENAME TO user_company;
ALTER TABLE account_images RENAME TO user_account_images;
ALTER TABLE data_load_history RENAME TO jq_data_load_history;
ALTER TABLE fips_lookup RENAME TO lookup_fips_codes;
ALTER TABLE account_use_types RENAME TO lookup_account_use_types;
ALTER TABLE us_states RENAME TO lookup_us_states;
ALTER TABLE data_normalization_config RENAME TO config_data_normalization;
ALTER TABLE keystore RENAME TO config_keystore;
ALTER TABLE external_accounts RENAME TO config_external_accounts;
ALTER TABLE notification RENAME TO config_notification;
ALTER TABLE normal_listing_data RENAME TO data_normal_listing;
ALTER TABLE normal_tax_data RENAME TO data_normal_tax;
ALTER TABLE normal_deed_data RENAME TO data_normal_deed;
ALTER TABLE combined_data RENAME TO data_combined;
ALTER TABLE combined_data_deletes RENAME TO data_combined_deletes;

-- this is an old remnant of having a completely separate admin app
ALTER TABLE auth_session_security DROP COLUMN app;

ALTER TABLE auth_user DROP CONSTRAINT fk_auth_user_us_state_id;
ALTER TABLE user_company DROP CONSTRAINT fk_company_us_state_id;
ALTER TABLE lookup_mls DROP CONSTRAINT lookup_mls_state_id_fk;

DROP TABLE lookup_us_states;

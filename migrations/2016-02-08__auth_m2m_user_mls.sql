DELETE FROM auth_m2m_user_mls;

ALTER TABLE auth_m2m_user_mls
  ADD COLUMN mls_user_id varchar NOT NULL,
  ADD COLUMN is_verified boolean NOT NULL DEFAULT 'F';

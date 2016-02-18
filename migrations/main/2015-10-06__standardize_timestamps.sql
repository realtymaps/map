
-- bookshelf was handling this before, so this change just makes this table work like our others

ALTER TABLE auth_session_security RENAME COLUMN created_at TO rm_inserted_time;
ALTER TABLE auth_session_security ALTER COLUMN rm_inserted_time TYPE TIMESTAMP WITHOUT TIME ZONE;
ALTER TABLE auth_session_security ALTER COLUMN rm_inserted_time SET DEFAULT now_utc();

ALTER TABLE auth_session_security RENAME COLUMN updated_at TO rm_modified_time;
ALTER TABLE auth_session_security ALTER COLUMN rm_modified_time TYPE TIMESTAMP WITHOUT TIME ZONE;
ALTER TABLE auth_session_security ALTER COLUMN rm_modified_time SET DEFAULT now_utc();

CREATE TRIGGER update_modified_time_session_security
  BEFORE UPDATE ON auth_session_security
  FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

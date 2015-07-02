ALTER TABLE auth_user_profile
  ADD COLUMN rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  ADD COLUMN rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc();

ALTER TABLE project
  ADD COLUMN rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  ADD COLUMN rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc();

CREATE TRIGGER update_modified_time_auth_user_profile
  BEFORE UPDATE ON auth_user_profile
  FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

CREATE TRIGGER update_modified_time_project
  BEFORE UPDATE ON project
  FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

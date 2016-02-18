CREATE OR REPLACE FUNCTION f_update_mlses_verified() RETURNS TRIGGER AS $$
BEGIN
  IF col_exists(TG_TABLE_NAME::regclass, 'auth_user_id'::text) AND
    col_exists(TG_TABLE_NAME::regclass, 'mls_code'::text) THEN
    IF TG_OP='DELETE' THEN
      UPDATE auth_user
        SET mlses_verified=f_get_mlses_verified_by_auth_user_id(OLD.auth_user_id)
      WHERE id = OLD.auth_user_id;
    ELSIF TG_OP='INSERT' THEN
      UPDATE auth_user
        SET mlses_verified=f_get_mlses_verified_by_auth_user_id(NEW.auth_user_id)
      WHERE id = NEW.auth_user_id;
    ELSE
      IF NEW.mls_code <> OLD.mls_code THEN
        UPDATE auth_user
          SET mlses_verified=f_get_mlses_verified_by_auth_user_id(NEW.auth_user_id)
        WHERE id = NEW.auth_user_id;
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION f_update_fips_codes() RETURNS TRIGGER AS $$
BEGIN
  IF col_exists(TG_TABLE_NAME::regclass, 'auth_user_id'::text) AND
    col_exists(TG_TABLE_NAME::regclass, 'mls_code'::text) THEN
    IF TG_OP='DELETE' THEN
      UPDATE auth_user
        SET fips_codes=f_get_fips_codes_by_auth_user_id(OLD.auth_user_id)
      WHERE id = OLD.auth_user_id;
    ELSIF TG_OP='INSERT' THEN
      UPDATE auth_user
        SET fips_codes=f_get_fips_codes_by_auth_user_id(NEW.auth_user_id)
      WHERE id = NEW.auth_user_id;
    ELSE
      IF NEW.mls_code <> OLD.mls_code THEN
        UPDATE auth_user
          SET fips_codes=f_get_fips_codes_by_auth_user_id(NEW.auth_user_id)
        WHERE id = NEW.auth_user_id;
      END IF;
    END IF;
  ELSIF col_exists(TG_TABLE_NAME::regclass, 'auth_user_id'::text) AND
    col_exists(TG_TABLE_NAME::regclass, 'fips_code'::text) THEN
    IF TG_OP='DELETE' THEN
      UPDATE auth_user
        SET fips_codes=f_get_fips_codes_by_auth_user_id(OLD.auth_user_id)
      WHERE id = OLD.auth_user_id;
    ELSIF TG_OP='INSERT' THEN
      UPDATE auth_user
        SET fips_codes=f_get_fips_codes_by_auth_user_id(NEW.auth_user_id)
      WHERE id = NEW.auth_user_id;
    ELSE
      IF NEW.fips_code <> OLD.fips_code THEN
        UPDATE auth_user
          SET fips_codes=f_get_fips_codes_by_auth_user_id(NEW.auth_user_id)
        WHERE id = NEW.auth_user_id;
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

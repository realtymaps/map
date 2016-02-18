CREATE OR REPLACE FUNCTION update_email_validation_hash_update_time() RETURNS TRIGGER AS $$
BEGIN
  IF col_exists(TG_TABLE_NAME::regclass, 'email_validation_hash'::text) AND
  col_exists(TG_TABLE_NAME::regclass, 'email_validation_hash_update_time'::text) THEN
    IF NEW.email_validation_hash IS NOT NULL THEN
      NEW.email_validation_hash_update_time = NOW();
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

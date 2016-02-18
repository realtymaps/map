SELECT f_add_col('auth_user', 'cancel_email_hash', 'varchar');

ALTER TABLE auth_user DROP COLUMN IF EXISTS email_validation_hash_created_time;

CREATE TRIGGER update_email_validation_hash_update_time_auth_user
BEFORE UPDATE ON auth_user
FOR EACH ROW EXECUTE PROCEDURE update_email_validation_hash_update_time();

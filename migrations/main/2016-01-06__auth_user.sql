SELECT f_add_default_col('auth_user', 'email_is_valid', 'bool', 'false');
SELECT f_add_col('auth_user', 'email_validation_hash', 'varchar');
SELECT f_add_default_col('auth_user', 'email_validation_attempt', 'int','0');

-- times and count to protect against abuse validation creation in a specific timespan
SELECT f_add_col('auth_user', 'email_validation_hash_created_time', 'TIMESTAMP');
SELECT f_add_col('auth_user', 'email_validation_hash_update_time', 'TIMESTAMP');

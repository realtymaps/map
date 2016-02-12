SELECT f_add_default_col('auth_user', 'is_test', 'bool', 'false');

UPDATE auth_user
  SET is_test=TRUE
WHERE stripe_customer_id is not null;

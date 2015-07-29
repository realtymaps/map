ALTER TABLE auth_user DROP CONSTRAINT auth_user_username_key;

UPDATE auth_user set email = 'invalid' || id where email = '';

ALTER TABLE auth_user ADD CONSTRAINT auth_user_email_unique_key UNIQUE (email)
 NOT DEFERRABLE INITIALLY IMMEDIATE;

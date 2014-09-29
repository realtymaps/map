CREATE TABLE "session_security" (
  "id" serial NOT NULL PRIMARY KEY,
  "user_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED,
  "session_id" varchar(64) NOT NULL,
  "remember_me" boolean NOT NULL,
  "series_salt" varchar(32) NOT NULL,
  "next_security_token" varchar(32) NOT NULL,
  "current_security_token" varchar(32),
  "previous_security_token" varchar(32),
  "created_at" timestamp with time zone NOT NULL,
  "updated_at" timestamp with time zone NOT NULL
);

UPDATE auth_group SET name = 'Free Tier' WHERE name = 'Free tier';
UPDATE auth_group SET name = 'Basic Tier' WHERE name = 'Basic tier';

INSERT INTO management_environmentsetting (setting_name, setting_value, setting_type, environment_name) VALUES ('token hashing cost factor', '11', 'integer', 'all_environments');

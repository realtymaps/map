CREATE TABLE "session_security" (
  "id" serial NOT NULL PRIMARY KEY,
  "user_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED,
  "session_id" varchar(64) NOT NULL,
  "remember_me" boolean NOT NULL,
  "next_security_token" varchar(64) NOT NULL,
  "current_security_token" varchar(64),
  "previous_security_token" varchar(64),
  "created_at" timestamp with time zone NOT NULL,
  "updated_at" timestamp with time zone NOT NULL
);

UPDATE auth_group SET name = 'Free Tier' WHERE name = 'Free tier';
UPDATE auth_group SET name = 'Basic Tier' WHERE name = 'Basic tier';

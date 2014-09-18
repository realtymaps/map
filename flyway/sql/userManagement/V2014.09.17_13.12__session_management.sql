CREATE TABLE "session_security" (
  "id" serial NOT NULL PRIMARY KEY,
  "user_id" integer NOT NULL UNIQUE REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED,
  "session_id" varchar(64) NOT NULL,
  "remember_me" boolean NOT NULL,
  "next_security_token" varchar(64) NOT NULL,
  "current_security_token" varchar(64),
  "previous_security_token" varchar(64),
  "created" timestamp with time zone NOT NULL,
  "semi_expiration" timestamp with time zone NOT NULL
);

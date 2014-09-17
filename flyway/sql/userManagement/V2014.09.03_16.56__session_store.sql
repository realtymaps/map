
INSERT INTO management_environmentsetting (setting_name, setting_value, setting_type, environment_name) VALUES ('password hashing cost factor', '13', 'integer', 'all_environments');

CREATE TABLE "session" (
  "sid" varchar NOT NULL COLLATE "default",
	"sess" json NOT NULL,
	"expire" timestamp(6) NOT NULL
)
WITH (OIDS=FALSE);
ALTER TABLE "session" ADD CONSTRAINT "session_pkey" PRIMARY KEY ("sid") NOT DEFERRABLE INITIALLY IMMEDIATE;


alter table user_state rename to auth_user_profile;

alter table auth_user_profile
ADD COLUMN parent_auth_user_id int4,
ADD COLUMN auth_user_id int4,
ADD COLUMN name varchar,
ADD COLUMN project_id int4;

update auth_user_profile
set auth_user_id = id;

ALTER TABLE auth_user_profile DROP COLUMN "id";

alter table auth_user_profile ADD COLUMN id serial;
ALTER TABLE auth_user_profile ADD CONSTRAINT "auth_user_profile_pkey" PRIMARY KEY ("id");

ALTER TABLE auth_user_profile ALTER COLUMN auth_user_id SET NOT NULL;

ALTER TABLE auth_user_profile ADD CONSTRAINT auth_profile_parent_auth_user_id_fkey
FOREIGN KEY ("parent_auth_user_id") REFERENCES "auth_user" ("id")
ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE auth_user_profile ADD CONSTRAINT auth_profile_auth_user_id_fkey
FOREIGN KEY ("auth_user_id") REFERENCES "auth_user" ("id")
ON UPDATE CASCADE ON DELETE CASCADE;


CREATE TABLE project (
	id serial,
    name varchar,
    PRIMARY KEY (id)
)
WITH (OIDS=FALSE);


ALTER TABLE auth_user_profile ADD CONSTRAINT auth_profile_project_id_fkey
FOREIGN KEY ("project_id") REFERENCES "project" ("id")
ON UPDATE CASCADE ON DELETE CASCADE;

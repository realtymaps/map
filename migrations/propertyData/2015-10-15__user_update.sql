ALTER TABLE auth_user ADD COLUMN rm_inserted_time timestamp without time zone DEFAULT now_utc() NOT NULL;
ALTER TABLE auth_user ADD COLUMN rm_modified_time timestamp without time zone DEFAULT now_utc() NOT NULL;
ALTER TABLE auth_user ADD COLUMN date_invited timestamp with time zone;
ALTER TABLE auth_user ADD COLUMN parent_id integer;

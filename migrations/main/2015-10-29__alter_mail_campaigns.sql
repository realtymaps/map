ALTER TABLE user_mail_campaigns ALTER COLUMN created SET DEFAULT now_utc();
ALTER TABLE user_mail_campaigns RENAME COLUMN created TO rm_inserted_time;
ALTER TABLE user_mail_campaigns ADD COLUMN rm_modified_time timestamp without time zone DEFAULT now_utc() NOT NULL;

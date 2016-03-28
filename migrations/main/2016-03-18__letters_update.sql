DELETE FROM user_mail_letters;
ALTER TABLE user_mail_letters ADD COLUMN rm_property_id TEXT NOT NULL;

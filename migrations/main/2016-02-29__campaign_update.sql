ALTER TABLE user_mail_campaigns ADD COLUMN content_url text;
ALTER TABLE user_mail_campaigns DROP COLUMN lob_batch_id;
ALTER TABLE user_mail_campaigns DROP COLUMN count;
ALTER TABLE user_mail_campaigns DROP COLUMN lob_content;
ALTER TABLE user_mail_campaigns DROP COLUMN submitted;

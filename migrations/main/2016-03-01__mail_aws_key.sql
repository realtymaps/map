ALTER TABLE user_mail_campaigns DROP COLUMN content_url;
ALTER TABLE user_mail_campaigns ADD COLUMN aws_key text;
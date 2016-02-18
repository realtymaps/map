ALTER TABLE user_mail_campaigns ALTER COLUMN template_id TYPE TEXT;
ALTER TABLE user_mail_campaigns RENAME COLUMN template_id TO template_type;
ALTER TABLE user_mail_letters ADD COLUMN lob_api text;
UPDATE user_mail_letters set lob_api='test';

DROP TABLE IF EXISTS user_pdf_uploads;

CREATE TABLE user_pdf_uploads (
  aws_key text,
  filename text,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  last_used_mail_campaign_id int,
  PRIMARY KEY (aws_key)
);

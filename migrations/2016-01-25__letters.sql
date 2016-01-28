CREATE TABLE IF NOT EXISTS user_mail_letters (
  id serial,
  auth_user_id int4 NOT NULL,
  user_mail_campaign_id integer NOT NULL,
  address_to json not null,
  address_from json not null,
  file text,
  options json,
  status text,
  lob_response json,
  retries integer DEFAULT 0,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE
);

CREATE TABLE account_use_types (
	"id" SERIAL NOT NULL,
	"type" varchar,
  "description" varchar,
	PRIMARY KEY ("id")
)
WITH (OIDS=FALSE);

insert into account_use_types (type, description)
values
('realtor', 'I''m a realtor.'),
('real estate developer', 'I''m real estate developer.'),
('real estate investor', 'I''m real estate investor.'),
('property manager', 'I''m property manager.'),
('own residence', 'I''m doing research to buy or sell my own residence.'),
('staff', 'I''m a staff memeber.');

CREATE TABLE account_images (
	"id" SERIAL NOT NULL,
	"blob" bytea,
  "gravatar_url" varchar,
	PRIMARY KEY ("id")
)
WITH (OIDS=FALSE);


-- root images for a user account
alter table auth_user add column account_image_id int4;
ALTER TABLE auth_user ADD CONSTRAINT "fk_auth_user_account_image_id" FOREIGN KEY (account_image_id) references account_images(id) ON UPDATE CASCADE ON DELETE SET NULL;

-- profile images for a user account which can override what client sees if it
-- is derrived from a profile account
alter table auth_user_profile add column account_image_id int4;
ALTER TABLE auth_user_profile ADD CONSTRAINT "fk_auth_user_profile_account_image_id" FOREIGN KEY (account_image_id) references account_images(id) ON UPDATE CASCADE ON DELETE SET NULL;

CREATE TABLE company (
	"id" SERIAL NOT NULL,
	"address_1" varchar,
  "address_2" varchar,
	"city" varchar,
  "zip" varchar,
  "us_state_id" int,
  "phone" varchar,
  "fax" varchar,
  "website_url" varchar,
  "account_photo_id" int references account_images(id) ON UPDATE CASCADE ON DELETE SET NULL,
	PRIMARY KEY ("id")
)
WITH (OIDS=FALSE);

ALTER TABLE company ADD CONSTRAINT "fk_company_us_state_id" FOREIGN KEY (us_state_id) REFERENCES auth_user (id) ON UPDATE CASCADE ON DELETE SET NULL;

alter table auth_user add column us_state_id int4;
ALTER TABLE auth_user ADD CONSTRAINT "fk_auth_user_us_state_id" FOREIGN KEY (us_state_id) REFERENCES auth_user (id) ON UPDATE CASCADE ON DELETE SET NULL;
alter table auth_user add column address_1 varchar;
alter table auth_user add column address_2 varchar;
alter table auth_user add column zip varchar;
alter table auth_user add column website_url varchar;
alter table auth_user add column account_use_type_id int;
alter table auth_user add column city varchar;
ALTER TABLE auth_user ADD CONSTRAINT "fk_auth_user_account_use_type_id" FOREIGN KEY (account_use_type_id) REFERENCES account_use_types (id) ON UPDATE CASCADE ON DELETE SET NULL;

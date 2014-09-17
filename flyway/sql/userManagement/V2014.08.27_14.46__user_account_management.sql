
SELECT setval('auth_user_id_seq', (SELECT MAX(id) FROM auth_user));

SELECT setval('django_content_type_id_seq', (SELECT MAX(id) FROM django_content_type));
INSERT INTO django_content_type (name, app_label, model) VALUES ('feature', 'management', 'feature');

SELECT setval('auth_permission_id_seq', (SELECT MAX(id) FROM auth_permission));
INSERT INTO auth_permission (name, content_type_id, codename) VALUES ('Unlimited logins', (SELECT id FROM django_content_type WHERE name='feature'), 'unlimited_logins');

SELECT setval('auth_group_id_seq', (SELECT MAX(id) FROM auth_group));
INSERT INTO auth_group (name) VALUES ('Free tier');
INSERT INTO auth_group (name) VALUES ('Basic tier');
INSERT INTO auth_group (name) VALUES ('Standard Tier');
INSERT INTO auth_group (name) VALUES ('Premium Tier');


CREATE TABLE "management_useraccountprofile" (
  "id" serial NOT NULL PRIMARY KEY,
  "user_id" integer NOT NULL UNIQUE REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED,
  "suspended" boolean NOT NULL,
  "override_basic_monthly_charge" double precision,
  "override_basic_yearly_charge" double precision,
  "override_basic_num_logins" integer,
  "override_standard_monthly_charge" double precision,
  "override_standard_yearly_charge" double precision,
  "override_standard_num_logins" integer,
  "override_premium_monthly_charge" double precision,
  "override_premium_yearly_charge" double precision,
  "override_premium_num_logins" integer,
  "notes" text NOT NULL
);

CREATE TABLE "management_useraccountbalance" (
  "id" serial NOT NULL PRIMARY KEY,
  "user_id" integer NOT NULL UNIQUE REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED,
  "subscription_balance" double precision,
  "a_la_cart_balance" double precision
);

CREATE OR REPLACE FUNCTION user_inserts() RETURNS text AS $$
DECLARE
  auth_user_row  auth_user%ROWTYPE;
BEGIN
  FOR auth_user_row IN SELECT id FROM auth_user LOOP
    INSERT INTO management_useraccountprofile (user_id, suspended, override_basic_monthly_charge, override_basic_yearly_charge, override_basic_num_logins, override_standard_monthly_charge, override_standard_yearly_charge, override_standard_num_logins, override_premium_monthly_charge, override_premium_yearly_charge, override_premium_num_logins, notes) VALUES (auth_user_row.id, false, 0, 0, NULL, 0, 0, NULL, 0, 0, NULL, '');
    INSERT INTO management_useraccountbalance (user_id, subscription_balance, a_la_cart_balance) VALUES (auth_user_row.id, 0, 0);
  END LOOP;
  RETURN '';
END;
$$ LANGUAGE 'plpgsql';
SELECT user_inserts();

CREATE TABLE "management_environmentsetting" (
  "id" serial NOT NULL PRIMARY KEY,
  "setting_name" varchar(64) NOT NULL,
  "setting_value" varchar(1024) NOT NULL,
  "setting_type" varchar(16) NOT NULL,
  "environment_name" varchar(64) NOT NULL,
  UNIQUE ("setting_name", "environment_name")
);
INSERT INTO management_environmentsetting (setting_name, setting_value, setting_type, environment_name) VALUES ('default basic monthly charge', '19.99', 'decimal', 'all_environments');
INSERT INTO management_environmentsetting (setting_name, setting_value, setting_type, environment_name) VALUES ('default standard monthly charge', '29.99', 'decimal', 'all_environments');
INSERT INTO management_environmentsetting (setting_name, setting_value, setting_type, environment_name) VALUES ('default premium monthly charge', '99.99', 'decimal', 'all_environments');
INSERT INTO management_environmentsetting (setting_name, setting_value, setting_type, environment_name) VALUES ('default basic yearly charge', '225', 'decimal', 'all_environments');
INSERT INTO management_environmentsetting (setting_name, setting_value, setting_type, environment_name) VALUES ('default premium yearly charge', '1100', 'decimal', 'all_environments');
INSERT INTO management_environmentsetting (setting_name, setting_value, setting_type, environment_name) VALUES ('default standard yearly charge', '300', 'decimal', 'all_environments');
INSERT INTO management_environmentsetting (setting_name, setting_value, setting_type, environment_name) VALUES ('default basic logins', '1', 'integer', 'all_environments');
INSERT INTO management_environmentsetting (setting_name, setting_value, setting_type, environment_name) VALUES ('default standard logins', '1', 'integer', 'all_environments');
INSERT INTO management_environmentsetting (setting_name, setting_value, setting_type, environment_name) VALUES ('default premium logins', '2', 'integer', 'all_environments');
INSERT INTO management_environmentsetting (setting_name, setting_value, setting_type, environment_name) VALUES ('default free logins', '1', 'integer', 'all_environments');


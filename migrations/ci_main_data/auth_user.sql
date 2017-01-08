INSERT INTO "auth_user"
  ("first_name", "last_name", "email", "fips_codes")
VALUES ('Bob', 'Spec', 'blackhole@realtymaps.com', '["12021"]');


insert into auth_user (
  "password",
  "is_superuser",
  "first_name", "last_name", "email", "is_staff", "is_active",
  "email_validation_attempt", "email_is_valid", "is_test")
values (
  'bcrypt$$2a$13$3PMlCvGKId961ZNCwOXYNu258sVLkHGzr6OLc.NUcy7a36s0XVGza',
  'f',
  'CIRCLE', 'CI', 'devs@realtymaps.com', 'f', 't',
  '0', 't', 't');

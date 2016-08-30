INSERT INTO "auth_user"
  ("username", "first_name", "last_name", "email", "fips_codes")
VALUES ('user1', 'Bob', 'Spec', 'blackhole@realtymaps.com', '["12021"]');


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

insert into auth_m2m_user_groups (user_id, group_id)
values (
  (select id from auth_user where first_name = 'CIRCLE' and last_name = 'CI'),
  (select id from auth_group where name = 'Premium Tier')
);

insert into auth_m2m_user_mls (mls_code, auth_user_id, mls_user_id, is_verified)
values(
  'SWFLMLS',
  (select id from auth_user where first_name = 'CIRCLE' and last_name = 'CI'),
  '123456',
  TRUE
);

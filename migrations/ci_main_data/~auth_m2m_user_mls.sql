-- this file references other tables, so it has been prefixed with ~ so that it comes later alphabetically

insert into auth_m2m_user_mls (mls_code, auth_user_id, mls_user_id, is_verified)
values(
  'SWFLMLS',
  (select id from auth_user where first_name = 'CIRCLE' and last_name = 'CI'),
  '123456',
  TRUE
);

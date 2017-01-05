insert into auth_m2m_user_groups (user_id, group_id)
values (
  (select id from auth_user where first_name = 'CIRCLE' and last_name = 'CI'),
  (select id from auth_group where name = 'Premium Tier')
);

DELETE FROM auth_m2m_user_permissions WHERE permission_id in (SELECT id from auth_permission WHERE codename in ('access_premium','access_standard'));
DELETE FROM auth_m2m_user_groups WHERE group_id in (SELECT id from auth_group WHERE name in ('Premium Tier','Standard Tier'));

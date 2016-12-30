INSERT INTO auth_permission (id, name, codename) values (47, 'Can login as other users.', 'spoof_user');

INSERT INTO auth_m2m_user_permissions (user_id, permission_id) (
  SELECT id, 47 FROM auth_user WHERE is_superuser=true
);

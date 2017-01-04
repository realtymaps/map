INSERT INTO auth_permission (name, codename) values ('Can login as other users.', 'spoof_user');

INSERT INTO auth_m2m_user_permissions (user_id, permission_id) (
  SELECT u.id, perm.id
  FROM auth_user as u
  join auth_permission perm on perm.codename = 'spoof_user'
  where u.is_superuser=true
);

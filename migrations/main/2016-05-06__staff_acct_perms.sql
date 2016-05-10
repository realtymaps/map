-- for staff members without stripe subscriptions, we can control subscription access with these perms
INSERT INTO auth_permission (name, codename) VALUES ('Can access premium content', 'access_premium');
INSERT INTO auth_permission (name, codename) VALUES ('Can access standard content', 'access_standard');

-- go ahead and give premium to all current staff
INSERT INTO auth_m2m_user_permissions (user_id, permission_id)
SELECT auth_user.id, auth_permission.id
FROM auth_user, auth_permission
WHERE auth_permission.codename = 'access_premium'
  AND auth_user.is_staff = true;

INSERT INTO auth_m2m_group_permissions (group_id, permission_id) (
  SELECT g.id as group_id, p.id as permission_id
  FROM auth_group g, auth_permission p
  WHERE g.name = 'Premium Tier' and p.codename = 'access_premium');

INSERT INTO auth_m2m_group_permissions (group_id, permission_id) (
  SELECT g.id as group_id, p.id as permission_id
  FROM auth_group g, auth_permission p
  WHERE g.name = 'Standard Tier' and p.codename = 'access_standard');

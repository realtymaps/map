UPDATE user_profile
SET
  can_edit = true
WHERE
  parent_auth_user_id is NULL;

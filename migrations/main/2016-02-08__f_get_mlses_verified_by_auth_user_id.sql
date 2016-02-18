CREATE OR REPLACE FUNCTION f_get_mlses_verified_by_auth_user_id(auth_user_id_arg INT4)
RETURNS JSON AS $$
  SELECT array_to_json(f_array_sort_unique(array_agg(mls_code)))
  FROM (
  SELECT auth_user_id, mls_code
  FROM auth_m2m_user_mls
  where is_verified = TRUE
  ) subQ
  where subQ.auth_user_id = auth_user_id_arg;
$$
LANGUAGE sql;

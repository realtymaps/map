CREATE OR REPLACE FUNCTION f_get_fips_codes_by_auth_user_id(auth_user_id_arg INT4)
RETURNS JSON AS $$
  SELECT array_to_json(f_array_sort_unique(array_agg(fips_code)))
  FROM (
  SELECT m2m_loc.auth_user_id, adj.neighbor_fips_code as fips_code
  FROM lookup_county_adjacents adj
  JOIN auth_m2m_user_locations m2m_loc on m2m_loc.fips_code = adj.parent_fips_code

  UNION

  SELECT m2m_mls.auth_user_id, mlsFips.fips_code
  FROM lookup_mls_fips_code mlsFips
  JOIN auth_m2m_user_mls m2m_mls on m2m_mls.mls_code = mlsFips.mls
  ) subQ
  where subQ.auth_user_id = auth_user_id_arg;
$$
LANGUAGE sql;

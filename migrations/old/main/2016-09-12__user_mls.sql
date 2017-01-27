UPDATE lookup_mls
SET mls = 'swflmls'
WHERE mls = 'SWFMLS';

UPDATE lookup_mls_m2m_fips_code_county
SET mls = 'swflmls'
WHERE mls = 'SWFMLS';

INSERT INTO auth_m2m_user_mls (mls_code, auth_user_id, mls_user_id, is_verified )
SELECT
  'swflmls', a.id, '', true
FROM
  auth_user a
WHERE
  a.is_superuser = true OR a.first_name = 'Dan';

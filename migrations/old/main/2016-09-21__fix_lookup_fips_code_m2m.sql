UPDATE lookup_mls_m2m_fips_code_county
SET
  mls = 'ARMLSAZ',
  fips_code = '0'||fips_code
WHERE mls = 'ARMLS';

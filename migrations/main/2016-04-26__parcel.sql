ALTER TABLE parcel ALTER COLUMN fips_code TYPE text;
update parcel set fips_code = LPAD("fips_code", 5, '0');
 

ALTER TABLE parcel add column data_source_uuid text;

update parcel
  set data_source_uuid=regexp_replace(regexp_replace(rm_property_id, fips_code||'_', '', 'g'),'_001','');

ALTER TABLE parcel ALTER COLUMN data_source_uuid SET NOT NULL;

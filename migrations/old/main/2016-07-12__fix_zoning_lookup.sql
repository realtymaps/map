
UPDATE config_data_source_fields
SET
  "LookupName" = 'STANDARDIZED_LAND_USE',
  "Interpretation" = 'Lookup'
WHERE "SystemName" = 'Assessors Land Use';


UPDATE config_data_normalization
SET
  config = (config::JSONB || '{"doLookup": true, "LookupName": "STANDARDIZED_LAND_USE", "Interpretation": "Lookup"}')::JSON
WHERE output = 'Assessors Land Use';


UPDATE config_data_source_fields
SET
  "LookupName" = 'STANDARDIZED_LAND_USE',
  "Interpretation" = 'Lookup'
WHERE "SystemName" = 'Standardized Land Use Code';


UPDATE config_data_normalization
SET
  config = (config::JSONB || '{"doLookup": true, "LookupName": "STANDARDIZED_LAND_USE", "Interpretation": "Lookup"}')::JSON
WHERE output = 'Standardized Land Use Code';


UPDATE config_data_normalization
SET
  config = jsonb_set(config::JSONB, '{mapping}', (config->>'map')::JSONB)::JSON
WHERE config->>'map' IS NOT NULL;


UPDATE config_data_normalization
SET
  config = (config::JSONB - 'map')::JSON
WHERE config->>'map' IS NOT NULL;


UPDATE config_data_normalization
SET
  config = jsonb_set(config::JSONB, '{mapping}', (config->>'map')::JSONB)::JSON
WHERE config->>'map' IS NOT NULL;


UPDATE config_data_normalization
SET
  config = (config::JSONB - 'map')::JSON
WHERE config->>'map' IS NOT NULL;

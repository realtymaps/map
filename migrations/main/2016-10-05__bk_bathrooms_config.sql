UPDATE config_data_normalization
SET config = jsonb_set(config::JSONB, '{implicit}', '{"full": 2}'::JSONB)::JSON
WHERE output = 'baths' AND data_source_id = 'blackknight' AND list = 'base';

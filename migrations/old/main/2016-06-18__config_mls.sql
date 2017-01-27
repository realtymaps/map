UPDATE config_mls
SET listing_data = jsonb_set(listing_data::JSONB, '{field_type}', '"Date"')::JSON, formal_name = 'Midwest Real Estate Data (MRED)'
WHERE id = 'MRED';

UPDATE config_mls
SET listing_data = jsonb_set(listing_data::JSONB, '{field_type}', '"DateTime"')::JSON, formal_name = 'Sunshine MLS (SWFLMLS)'
WHERE id = 'swflmls';

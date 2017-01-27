update data_combined set baths = jsonb_set(baths::jsonb, '{value}', '"-"', true)::json where (baths->'value')::text = '"unknown"';

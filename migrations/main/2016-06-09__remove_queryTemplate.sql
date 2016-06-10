UPDATE config_mls SET listing_data = jsonb_strip_nulls(jsonb_set(listing_data, '{queryTemplate}', 'null', false));

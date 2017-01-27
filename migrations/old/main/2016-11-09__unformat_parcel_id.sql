UPDATE config_data_normalization
SET config = config::JSONB - 'stripFormatting'
WHERE output = 'parcel_id';

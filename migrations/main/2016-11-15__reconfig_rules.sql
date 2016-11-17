UPDATE config_data_normalization
SET config = '{"DataType":"Int","nullEmpty":true,"nullZero":true}'
WHERE output = 'Lot Size - Frontage Feet' or output = 'Lot Size - Depth Feet';

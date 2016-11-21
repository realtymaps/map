
UPDATE config_data_source_fields
SET "DataType" = 'Decimal'
WHERE
  data_source_id = 'blackknight'
  AND data_list_type = 'tax'
  AND "SystemName" = 'Tax Amount';

UPDATE config_data_normalization
SET config = '{"DataType":"Decimal","nullZero":true,"nullEmpty":true,"deliminate":true,"addDollarSign":true}'::JSON
WHERE
  data_source_id = 'blackknight'
  AND list = 'tax'
  AND output = 'Tax Amount';

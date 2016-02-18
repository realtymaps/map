UPDATE config_data_source_fields SET "DataType" = 'Int'
WHERE data_source_id = 'blackknight' AND "SystemName" IN (
  'Lot Size - Acres',
  'Lot Size - Square Feet',
  'Number of Baths',
  'Number of Bedrooms',
  'Number of Partial Baths',
  'Number of Units',
  '# of Buildings',
  '# of Plumbing Fixtures',
  '# of Stories',
  'Parking - # of Cars',
  'Prior Sale - Price',
  'Latest Valid - Price',
  'Prior Valid - Price',
  'Building Area 1',
  'Building Area 2',
  'Building Area 3',
  'Building Area 4',
  'Building Area 5',
  'Building Area 6',
  'Building Area 7',
  'Other Impr Building Area 1',
  'Other Impr Building Area 2',
  'Other Impr Building Area 3',
  'Other Impr Building Area 4',
  'Other Impr Building Area 5'
);

UPDATE config_data_normalization SET config = '{"DataType":"Int","nullZero":true}'
WHERE data_source_id = 'blackknight' AND output IN (
  'Lot Size - Acres',
  'Lot Size - Square Feet',
  'Number of Baths',
  'Number of Bedrooms',
  'Number of Partial Baths',
  'Number of Units',
  '# of Buildings',
  '# of Plumbing Fixtures',
  '# of Stories',
  'Parking - # of Cars',
  'Prior Sale - Price',
  'Latest Valid - Price',
  'Prior Valid - Price',
  'Building Area 1',
  'Building Area 2',
  'Building Area 3',
  'Building Area 4',
  'Building Area 5',
  'Building Area 6',
  'Building Area 7',
  'Other Impr Building Area 1',
  'Other Impr Building Area 2',
  'Other Impr Building Area 3',
  'Other Impr Building Area 4',
  'Other Impr Building Area 5'
);

UPDATE config_data_normalization SET config = '{"implicitDecimals":3}'
WHERE data_source_id = 'blackknight' AND output = 'acres';

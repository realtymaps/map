UPDATE data_normalization_config
  SET output = 'Status', input = NULL
  WHERE data_source_id = 'swflmls' AND list = 'general' AND output = 'status';

UPDATE data_normalization_config
  SET output = 'Address'
  WHERE data_source_id = 'swflmls' AND list = 'general' AND output = 'address';

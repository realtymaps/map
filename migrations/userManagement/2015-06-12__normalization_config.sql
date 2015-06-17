UPDATE data_normalization_config
  SET transform = NULL, required = FALSE
  WHERE data_source_id = 'swflmls' AND list = 'hidden' AND output = 'Listing On Internet YN';

UPDATE data_normalization_config
SET required = FALSE
WHERE data_source_id = 'swflmls' AND list = 'general' AND output = 'Status';

UPDATE data_normalization_config
SET required = FALSE
WHERE data_source_id = 'swflmls' AND list = 'general' AND output = 'Address';

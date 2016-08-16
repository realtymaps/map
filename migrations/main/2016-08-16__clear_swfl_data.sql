DELETE FROM data_combined where data_source_type = 'swflmls';

DELETE FROM config_keystore WHERE namespace = 'data update timestamps' AND "key" = 'swflmls';

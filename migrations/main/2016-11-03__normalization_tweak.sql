UPDATE config_data_normalization
SET output = 'appraised_value'
WHERE output = 'assessed_value';

DELETE FROM config_keystore WHERE namespace = 'data refresh timestamps' AND key = 'swflmls';
DELETE FROM config_keystore WHERE namespace = 'data update timestamps' AND key = 'swflmls';

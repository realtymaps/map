UPDATE config_data_normalization
SET input = ('{"acres":'||input||'}')::JSON
WHERE output = 'acres';

ALTER TABLE data_combined ADD COLUMN appraised_value NUMERIC;

DELETE FROM config_keystore WHERE namespace = 'data refresh timestamps' AND key = 'swflmls';
DELETE FROM config_keystore WHERE namespace = 'data update timestamps' AND key = 'swflmls';

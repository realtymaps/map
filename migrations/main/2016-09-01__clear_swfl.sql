
-- remove the data itself
DELETE FROM data_combined where data_source_type = 'mls' AND data_source_id = 'swflmls';

-- remove timestamps
DELETE FROM config_keystore WHERE namespace = 'data refresh timestamps' AND key = 'swflmls';
DELETE FROM config_keystore WHERE namespace = 'data update timestamps' AND key = 'swflmls';

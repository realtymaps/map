TRUNCATE TABLE data_combined;

DELETE FROM config_keystore WHERE namespace = 'blackknight process dates';
DELETE FROM config_keystore WHERE namespace = 'data update timestamps' AND "key" != 'digimaps';

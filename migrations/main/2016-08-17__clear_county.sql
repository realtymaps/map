-- This resets county data so that it can be reloaded with fixed deed info
DELETE FROM data_combined where data_source_type = 'county';

DELETE FROM config_keystore WHERE namespace = 'blackknight process dates';
DELETE FROM config_keystore WHERE namespace = 'data update timestamps' AND "key" = 'blackknight';
DELETE FROM config_keystore WHERE namespace = 'data refresh timestamps' AND "key" = 'blackknight';

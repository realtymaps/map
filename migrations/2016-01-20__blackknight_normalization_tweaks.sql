-- need to get rid of some bad data and create new rules via the admin
DELETE FROM config_data_normalization WHERE data_source_id = 'blackknight' AND list = 'base';


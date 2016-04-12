DELETE FROM config_data_normalization WHERE list = 'base' AND output = 'year_built';
DELETE FROM config_data_normalization WHERE list = 'base' AND output = 'fips_code';

TRUNCATE data_combined;

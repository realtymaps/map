UPDATE config_data_normalization
SET list = 'general', ordering = (ordering + 50)
WHERE list = 'details';

UPDATE config_data_normalization
SET list = 'deed', ordering = (ordering + 50)
WHERE list = 'mortgage' AND data_type = 'tax';

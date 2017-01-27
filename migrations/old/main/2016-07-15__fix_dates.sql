UPDATE config_data_normalization
SET output = 'recording_date'
WHERE
  output = 'close_date'
  AND data_source_id = 'blackknight'
  AND data_type = 'tax';

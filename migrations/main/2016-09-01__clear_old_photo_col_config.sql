DELETE FROM config_data_normalization
WHERE
  data_source_type = 'mls' AND
  output IN ('photos', 'cdn_photo', 'photo_last_mod_time', 'photo_count', 'photo_id');

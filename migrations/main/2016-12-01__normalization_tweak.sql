UPDATE config_data_normalization
SET config = JSONB_SET(JSONB_SET(config::JSONB, '{mapping,Closed}', '"sold"', FALSE), '{mapping,Backup}', '"pending"', FALSE)::JSON
WHERE
  data_source_id = 'RAPB'
  AND list = 'base'
  AND output = 'status'
  AND data_type = 'listing';

DELETE FROM config_keystore WHERE namespace = 'data refresh timestamps' AND key = 'RAPB';
DELETE FROM config_keystore WHERE namespace = 'data update timestamps' AND key = 'RAPB';

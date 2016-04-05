update config_data_normalization set ordering=22 where data_source_type = 'mls' and list='base' and output='photo_id';
update config_data_normalization set ordering=23 where data_source_type = 'mls' and list='base' and output='photo_count';
update config_data_normalization set ordering=24 where data_source_type = 'mls' and list='base' and output='photo_last_mod_time';

ALTER TABLE config_data_normalization ADD CONSTRAINT unique_rule UNIQUE (data_source_id, data_type, list, ordering);

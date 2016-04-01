alter table data_combined add column photo_last_mod_time timestamp;

-- col to represent our last successful save time compared to mls time "photo_last_mod_time"
-- this time will simply be photo_last_mod_time on a successful save
alter table data_combined add column photo_download_last_mod_time timestamp;

delete from config_data_normalization
where output = 'photo_last_mod_time' and input is Null;

insert into "config_data_normalization"
  ( "output",   "input",    "ordering", "config", "data_type", "data_source_id", "list", "required", "transform", "data_source_type")
  values
  ( 'photo_last_mod_time', '"Last Image Trans Date"',        '17', '{}', 'listing', 'GLVAR',   'base', 't', null, 'mls'),
  ( 'photo_last_mod_time', '"Photo Date"',                   '17', '{}', 'listing', 'MRED',    'base', 't', null, 'mls'),
  ( 'photo_last_mod_time', '"Photo Modification Timestamp"', '14', '{}', 'listing', 'swflmls', 'base', 't', null, 'mls');

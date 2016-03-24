delete from config_data_normalization
where "output" = 'photo_id' and "input"::text = '""';

insert into "config_data_normalization"
  ( "output",   "input",    "ordering", "config", "data_type", "data_source_id", "list", "required", "transform", "data_source_type")
  values
  ( 'photo_id', '"sysid"',            '17', '{}', 'listing', 'GLVAR',   'base', 't', null, 'mls'),
  ( 'photo_id', '"MLS #"',            '17', '{}', 'listing', 'MRED',    'base', 't', null, 'mls'),
  ( 'photo_id', '"Matrix Unique ID"', '14', '{}', 'listing', 'swflmls', 'base', 't', null, 'mls');

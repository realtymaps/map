alter table data_combined add column photo_count integer;

delete from config_data_normalization
where "output" = 'photo_count' and "input"::text is Null;

insert into "config_data_normalization"
  ( "output",   "input",    "ordering", "config", "data_type", "data_source_id", "list", "required", "transform", "data_source_type")
  values
  ( 'photo_count', '"Images"',      '17', '{}', 'listing', 'GLVAR',   'base', 't', null, 'mls'),
  ( 'photo_count', '"Photo Count"', '17', '{}', 'listing', 'MRED',    'base', 't', null, 'mls'),
  ( 'photo_count', '"Photo Count"', '14', '{}', 'listing', 'swflmls', 'base', 't', null, 'mls');

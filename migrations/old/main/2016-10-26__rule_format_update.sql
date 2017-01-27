-- booleans
update config_data_normalization
set config = jsonb_set(config::jsonb, '{truthyOutput}', '"yes"')
where list != 'base' AND config::jsonb @> '{"DataType": "Boolean"}'::jsonb;

update config_data_normalization
set config = jsonb_set(config::jsonb, '{falsyOutput}', '"no"')
where list != 'base' AND config::jsonb @> '{"DataType": "Boolean"}'::jsonb;

-- currency
update config_data_normalization
set config = jsonb_set(config::jsonb, '{deliminate}', 'true'::jsonb)
where list != 'base' AND output SIMILAR TO '%(Price|price|Amount|amount|Fee|fee|\$)%' AND (config::jsonb @> '{"DataType": "Int"}'::jsonb OR config::jsonb @> '{"DataType": "Decimal"}'::jsonb);

update config_data_normalization
set config = jsonb_set(config::jsonb, '{addDollarSign}', 'true'::jsonb)
where list != 'base' AND output SIMILAR TO '%(Price|price|Amount|amount|Fee|fee|\$)%' AND (config::jsonb @> '{"DataType": "Int"}'::jsonb OR config::jsonb @> '{"DataType": "Decimal"}'::jsonb);

-- dates
update config_data_normalization
set config = jsonb_set(config::jsonb, '{outputFormat}', '"MMMM Do, YYYY"')
where config::jsonb @> '{"DataType": "DateTime"}'::jsonb AND list != 'base';

-- itemized fields
update config_data_normalization
set config = jsonb_set(config::jsonb, '{deliminate}', 'true'::jsonb)
where data_source_id = 'blackknight' AND (output = 'Total Assessed Value' OR output = 'Market Value: Improvement' OR output = 'Market Value: Land' OR output = 'Total Market Value');

update config_data_normalization
set config = jsonb_set(config::jsonb, '{addDollarSign}', 'true'::jsonb)
where data_source_id = 'blackknight' AND (output = 'Total Assessed Value' OR output = 'Market Value: Improvement' OR output = 'Market Value: Land' OR output = 'Total Market Value');

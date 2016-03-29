alter table data_combined add column photos jsonb not null DEFAULT '{}'::json;

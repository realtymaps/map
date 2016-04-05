alter table listing add column photos jsonb not null DEFAULT '{}'::json;
alter table listing add column photo_import_error text;

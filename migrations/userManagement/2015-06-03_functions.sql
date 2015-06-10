create or replace function now_utc() returns timestamp as $$
  select now() at time zone 'utc';
  $$ language sql;

-- Stored Procedure for keeping modified_time always  fresh on real changes
CREATE OR REPLACE FUNCTION update_rm_modified_time_column()
  RETURNS TRIGGER AS '
BEGIN
  NEW.rm_modified_time = NOW();
  RETURN NEW;
END;
' LANGUAGE 'plpgsql';

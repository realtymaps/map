
CREATE OR REPLACE FUNCTION update_rm_modified_time_column()
  RETURNS TRIGGER AS $$
BEGIN
  NEW.rm_modified_time = now_utc();
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION public.now_utc() RETURNS timestamp without time zone AS $$
  select now() at time zone 'utc';
$$ LANGUAGE sql;

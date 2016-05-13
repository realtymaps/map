
SELECT drop_all_tables_like('deed_%');
SELECT drop_all_tables_like('mortgage_%');
SELECT drop_all_tables_like('tax_%');

TRUNCATE TABLE listing;
ALTER TABLE listing ADD COLUMN owner_name TEXT;
ALTER TABLE listing ADD COLUMN owner_name_2 TEXT;
ALTER TABLE listing ADD COLUMN zoning TEXT;

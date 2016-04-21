
SELECT drop_all_tables_like('deed_%');
SELECT drop_all_tables_like('mortgage_%');
SELECT drop_all_tables_like('tax_%');

ALTER TABLE listing ADD COLUMN baths_half INTEGER;
ALTER TABLE listing ADD COLUMN baths_total NUMERIC(4, 1);

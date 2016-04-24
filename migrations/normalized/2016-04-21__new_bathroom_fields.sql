
SELECT drop_all_tables_like('deed_%');
SELECT drop_all_tables_like('mortgage_%');
SELECT drop_all_tables_like('tax_%');

ALTER TABLE listing DROP COLUMN baths_full;
ALTER TABLE listing ADD COLUMN baths JSON;

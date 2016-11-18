
SELECT for_all_tables_like('tax_%', 'ALTER TABLE @ DROP COLUMN promoted_values');

ALTER TABLE listing DROP COLUMN owner_name;
ALTER TABLE listing DROP COLUMN owner_name2;
ALTER TABLE listing DROP COLUMN appraised_value;

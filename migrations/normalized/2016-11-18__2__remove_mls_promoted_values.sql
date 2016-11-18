
SELECT for_all_tables_like_do('tax_%', 'ALTER TABLE @ DROP COLUMN promoted_values');

ALTER TABLE listing DROP COLUMN owner_name;
ALTER TABLE listing DROP COLUMN owner_name_2;
ALTER TABLE listing DROP COLUMN appraised_value;

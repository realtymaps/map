
SELECT for_all_tables_like_do('tax_%', 'ALTER TABLE @ DROP IF EXISTS COLUMN promoted_values');

ALTER TABLE listing DROP COLUMN IF EXISTS owner_name;
ALTER TABLE listing DROP COLUMN IF EXISTS owner_name_2;
ALTER TABLE listing DROP COLUMN IF EXISTS appraised_value;

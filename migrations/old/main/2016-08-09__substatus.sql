ALTER TABLE data_combined
DROP COLUMN substatus;

DELETE FROM config_data_normalization
WHERE output = 'substatus';

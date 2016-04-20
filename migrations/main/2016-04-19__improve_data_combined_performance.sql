-- rows in data_combined don't get updated directly, so this trigger is 99% wasted overhead
DROP TRIGGER update_modified_time_combined_data ON data_combined;
ALTER TABLE data_combined DROP COLUMN rm_modified_time;

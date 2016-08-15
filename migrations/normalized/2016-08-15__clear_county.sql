# This resets county data so that it can be reloaded with fixed deed info
SELECT drop_all_tables_like('deed_%');
SELECT drop_all_tables_like('mortgage_%');
SELECT drop_all_tables_like('tax_%');
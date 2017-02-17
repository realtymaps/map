CREATE INDEX data_combined_close_date_status_idx ON data_combined (close_date, status);
CLUSTER data_combined USING data_combined_close_date_status_idx;
ANALYZE data_combined;

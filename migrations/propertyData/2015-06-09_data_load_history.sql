

ALTER TABLE data_load_history ADD COLUMN rm_modified_time timestamp NOT NULL DEFAULT now_utc();

CREATE TRIGGER update_data_load_history_rm_modified_time BEFORE
UPDATE ON data_load_history FOR EACH ROW EXECUTE PROCEDURE "update_rm_modified_time_column"();

COMMENT ON TRIGGER update_data_load_history_rm_modified_time ON data_load_history IS NULL;

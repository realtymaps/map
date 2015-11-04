-- NOTE: There are other triggers such as corelogic stuff (but that db is going away)
DROP TRIGGER update_modified_time_mls_data ON mls_data;
DROP TRIGGER update_modified_time_combined_data ON combined_data;

CREATE TRIGGER update_modified_time_mls_data
  BEFORE UPDATE ON mls_data
  FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

CREATE TRIGGER update_modified_time_combined_data
  BEFORE UPDATE ON combined_data
  FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

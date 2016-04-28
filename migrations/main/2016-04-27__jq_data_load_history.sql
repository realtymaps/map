/*
  overall error traceability (Not a specific row)
  ===============================================
  examples:
  - failure to open a dump file (csv, zip, whatever)
  - empty contents of a dump (.zip missing shape files)
*/
ALTER TABLE jq_data_load_history ADD COLUMN rm_valid bool NOT NULL DEFAULT 't';
ALTER TABLE jq_data_load_history ADD COLUMN rm_error_msg text;

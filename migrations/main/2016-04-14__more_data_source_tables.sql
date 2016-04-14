-------
CREATE TABLE config_data_source_databases (
  data_source_id TEXT,
  "ResourceID" TEXT,
  "StandardName" TEXT,
  "VisibleName" TEXT,
  "ObjectVersion" TEXT
);
CREATE UNIQUE INDEX ON config_data_source_databases (data_source_id, "ResourceID");

-------
CREATE TABLE config_data_source_objects (
  data_source_id TEXT,
  "VisibleName" TEXT
);
CREATE UNIQUE INDEX ON config_data_source_objects (data_source_id, "VisibleName");

-------
CREATE TABLE config_data_source_tables (
  data_source_id TEXT,
  data_list_type TEXT,
  "ClassName" TEXT,
  "StandardName" TEXT,
  "VisibleName" TEXT,
  "TableVersion" TEXT
);
CREATE UNIQUE INDEX ON config_data_source_tables (data_source_id, data_list_type, "ClassName");

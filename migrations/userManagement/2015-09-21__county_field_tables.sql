-- 
DROP TABLE IF EXISTS data_source_fields;
CREATE TABLE data_source_fields (
  "MetadataEntryID" SERIAL PRIMARY KEY,
  "SystemName" TEXT,
  "ShortName" TEXT,
  "LongName" TEXT,
  "DataType" TEXT,
  "Interpretation" TEXT,
  "LookupName" TEXT,
  "Description" TEXT,
  -- sourcedatatype
  data_source_id TEXT, -- CoreLogic, etc
  data_source_type TEXT, -- mls, county, etc
  data_list_type TEXT -- tax, deed, listing, etc
);


DROP TABLE IF EXISTS data_source_lookups;
CREATE TABLE data_source_lookups (
  "LookupName" TEXT,
  "LongValue" TEXT,
  "ShortValue" TEXT,
  "Value" TEXT
);

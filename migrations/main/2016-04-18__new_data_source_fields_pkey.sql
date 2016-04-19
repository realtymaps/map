ALTER TABLE config_data_source_fields DROP CONSTRAINT IF EXISTS config_data_source_fields_pkey;
ALTER TABLE config_data_source_fields ALTER COLUMN "MetadataEntryID" DROP NOT NULL;
ALTER TABLE config_data_source_fields ALTER COLUMN "MetadataEntryID" SET DEFAULT NULL;
ALTER TABLE config_data_source_fields ADD COLUMN id SERIAL PRIMARY KEY;

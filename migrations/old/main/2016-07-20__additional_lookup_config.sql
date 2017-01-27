INSERT INTO "config_data_source_lookups"("LookupName","LongValue","ShortValue","Value","data_source_id","data_source_type","data_list_type","MetadataEntryID")
(
  SELECT "LookupName","LongValue","ShortValue","Value","data_source_id","data_source_type",'mortgage' AS "data_list_type","MetadataEntryID"
  FROM config_data_source_lookups
  WHERE "LookupName" = 'STANDARDIZED_LAND_USE' AND data_list_type = 'tax'
);

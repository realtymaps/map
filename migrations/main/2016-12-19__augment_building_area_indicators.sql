DELETE FROM config_data_source_lookups WHERE "ShortValue" = 'WF' OR "ShortValue" = 'WU';
INSERT into config_data_source_lookups ("LookupName","LongValue","ShortValue","Value","data_source_id","data_source_type","data_list_type","MetadataEntryID")
(
  SELECT
    "LookupName",
    "LongValue" || ' - Unfinished' AS "LongValue",
    "ShortValue" || 'U' AS "ShortValue",
    "Value" || 'U' AS "Value",
    "data_source_id",
    "data_source_type",
    "data_list_type",
    "MetadataEntryID"
  FROM config_data_source_lookups
  WHERE
    "LookupName" = 'BUILDING_AREA_INDICATOR' AND
    data_source_id = 'blackknight' AND
    "Value" LIKE '_'  -- wildcard to get all single-letter values
);
INSERT into config_data_source_lookups ("LookupName","LongValue","ShortValue","Value","data_source_id","data_source_type","data_list_type","MetadataEntryID")
(
  SELECT
    "LookupName",
    "LongValue" || ' - Finished' AS "LongValue",
    "ShortValue" || 'F' AS "ShortValue",
    "Value" || 'F' AS "Value",
    "data_source_id",
    "data_source_type",
    "data_list_type",
    "MetadataEntryID"
  FROM config_data_source_lookups
  WHERE
    "LookupName" = 'BUILDING_AREA_INDICATOR' AND
    data_source_id = 'blackknight' AND
    "Value" LIKE '_'  -- wildcard to get all single-letter values
);


-- should assume all lookups are single value
UPDATE config_data_source_fields SET "Interpretation" = 'Lookup' where "Interpretation" = 'LookupMulti';

-- accounting for a forgotten field to designate as lookup
UPDATE config_data_source_fields SET "Interpretation" = 'Lookup' where "LookupName" = 'OWNER_CORPORATE_INDICATOR_FLAG' and data_list_type = 'tax';
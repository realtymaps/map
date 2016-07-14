
CREATE OR REPLACE FUNCTION set_data_source_lookup(IN data_source TEXT, IN field_name TEXT, IN lookup_name TEXT) RETURNS VOID
LANGUAGE plpgsql AS $$
  BEGIN
    EXECUTE 'UPDATE config_data_source_fields SET "LookupName" = '
            || quote_literal(lookup_name)
            || ', "Interpretation" = ''Lookup'' WHERE "SystemName" = '
            || quote_literal(field_name)
            || ' AND data_source_id = '
            || quote_literal(data_source);
    EXECUTE 'UPDATE config_data_normalization SET "config" = (config::JSONB || ''{"doLookup": true, "LookupName": "'
            || lookup_name
            || '", "Interpretation": "Lookup"}'')::JSON WHERE output = '
            || quote_literal(field_name)
            || ' AND data_source_id = '
            || quote_literal(data_source);
  END;
$$;

CREATE OR REPLACE FUNCTION set_data_source_lookup_multi(IN data_source TEXT, IN field_name TEXT, IN lookup_name TEXT, IN delimiter_text TEXT) RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE 'UPDATE config_data_source_fields SET "LookupName" = '
          || quote_literal(lookup_name)
          || ', "Interpretation" = ''LookupMulti'' WHERE "SystemName" = '
          || quote_literal(field_name)
          || ' AND data_source_id = '
          || quote_literal(data_source);
  EXECUTE 'UPDATE config_data_normalization SET "config" = (config::JSONB || ''{"doLookup": true, "LookupName": "'
          || lookup_name
          || '", "Interpretation": "LookupMulti", "split":"'
          || delimiter_text
          || '"}'')::JSON WHERE output = '
          || quote_literal(field_name)
          || ' AND data_source_id = '
          || quote_literal(data_source);
END;
$$;

CREATE OR REPLACE FUNCTION set_data_source_boolean(IN data_source TEXT, IN field_name TEXT, IN options_text TEXT) RETURNS VOID
LANGUAGE plpgsql AS $$
  BEGIN
    EXECUTE 'UPDATE config_data_normalization SET transform = ''[validators.boolean('
            || options_text
            || ')]'', config = ''{"DataType": "Boolean", "advanced": true}'' WHERE output = '
            || quote_literal(field_name)
            || ' AND data_source_id = '
            || quote_literal(data_source);
  END;
$$;


SELECT set_data_source_lookup('blackknight', 'Assessee/Owner Name Type', 'ASSESSEE_OWNER_NAME_TYPE');
SELECT set_data_source_lookup('blackknight', '2nd Assessee/Owner Name Type', 'ASSESSEE_OWNER_NAME_TYPE');
SELECT set_data_source_lookup('blackknight', 'Assessee/Owner Name Indicator', 'ASSESSEE_OWNER_NAME_IND');
SELECT set_data_source_lookup('blackknight', '2nd Assessee/Owner Name Indicator', 'ASSESSEE_OWNER_NAME_IND');
SELECT set_data_source_lookup('blackknight', 'Mail Care-Of Name Indicator', 'ASSESSEE_OWNER_NAME_IND');
SELECT set_data_source_lookup('blackknight', 'Heating Fuel Type', 'HEATING_FUEL_TYPE');
SELECT set_data_source_lookup('blackknight', 'Roof Type', 'ROOF_TYPE');

SELECT set_data_source_lookup_multi('blackknight', 'Interior Walls', 'INTERIOR_WALLS', '');
SELECT set_data_source_lookup_multi('blackknight', 'Other Rooms', 'OTHER_ROOMS', '');
SELECT set_data_source_lookup_multi('blackknight', 'Site Influence', 'SITE_INFLUENCE', '');
SELECT set_data_source_lookup_multi('blackknight', 'Topography', 'TOPOGRAPHY', '');

SELECT set_data_source_boolean('blackknight', 'California Homeowners Exemption', '{"truthy":["H"]}');
SELECT set_data_source_boolean('blackknight', 'DistressedSaleFlag', '{"truthy":["1"],"falsy":["0"]}');
SELECT set_data_source_boolean('blackknight', 'Equity Credit Line', '{"truthy":["1"],"falsy":["0"]}');
SELECT set_data_source_boolean('blackknight', 'Inter-Family', '{"truthy":["1"],"falsy":["0"]}');
SELECT set_data_source_boolean('blackknight', 'Stand-Alone Refi', '{"truthy":["1"],"falsy":["0"]}');
SELECT set_data_source_boolean('blackknight', 'Cash Purchase', '{"truthy":["1"],"falsy":["0"]}');
SELECT set_data_source_boolean('blackknight', 'Construction Loan', '{"truthy":["1"],"falsy":["0"]}');
SELECT set_data_source_boolean('blackknight', 'Residential Indicator', '{"truthy":["1"],"falsy":["0"]}');
SELECT set_data_source_boolean('blackknight', 'Adjustable Rate Rider', '{"truthy":["Y"]}');
SELECT set_data_source_boolean('blackknight', 'Prepayment Rider', '{"truthy":["Y"]}');


INSERT INTO "config_data_source_lookups"("LookupName","LongValue","ShortValue","Value","data_source_id","data_source_type","data_list_type","MetadataEntryID")
VALUES
  (E'REO_FLAG',E'REO Buyer',E'1',E'1',E'blackknight',E'county',E'deed',NULL),
  (E'REO_FLAG',E'REO Seller',E'2',E'2',E'blackknight',E'county',E'deed',NULL);
SELECT set_data_source_lookup('blackknight', 'REO-Flag', 'REO_FLAG');
UPDATE config_data_normalization SET "config" = (config::JSONB || '{"unmapped": "null"}') WHERE data_source_id = 'blackknight' AND output = 'REO-Flag';

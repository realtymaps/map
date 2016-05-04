update config_data_normalization
  set config = '{"map":{"Two to Four Units":"Multi-Family","Mobile Home":"Single Family","Detached Single":"Single Family","Attached Single":"Condo / Townhome"}}',
      input = '"Property Type"'
  where data_source_id = 'MRED' and list = 'base' and output = 'property_type';

update config_data_normalization
  set config = '{"map":{"Single Family":"Single Family","Fractional":"Condo / Townhome","Condo":"Condo / Townhome","Co-Op":"Condo / Townhome","Timeshare":"Condo / Townhome"}}',
      input = '"Ownership Desc"'
  where data_source_id = 'swflmls' and list = 'base' and output = 'property_type';

update config_data_normalization
  set config = '{"map":{"Single Family Res":"Single Family","High Rise":"Condo / Townhome","Multiple Dwelling":"Multi-Family","Vacant/Subdivided Land":"Lots","Residential Rental":"Single Family","Builder":"Single Family","Commercial/Industrial":"Lots","Ofc/Ind/Retail Lease":"Condo / Townhome","Business Opportunity":"Lots"}}',
      input = '"Property Type"'
  where data_source_id = 'GLVAR' and list = 'base' and output = 'property_type';


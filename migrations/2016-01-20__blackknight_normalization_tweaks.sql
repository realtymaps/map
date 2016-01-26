-- need to get rid of some bad data and re-create the rules
DELETE FROM config_data_normalization WHERE data_source_id = 'blackknight' AND list = 'base';

INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'rm_property_id', 0, true, '{"fipsCode":"FIPS Code","apn":"Assessor’s Parcel Number"}', NULL, '{}', 'county', 'tax');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'address', 1, false, '{"city":"Property City Name","streetFull":"Property Full Street Address","state":"Property State","streetDirPrefix":"Property Street Direction Left","streetDirSuffix":"Property Street Direction Right","streetName":"Property Street Name","streetSuffix":"Property Street Suffix","unitNum":"Property Unit Number","zip9":"Property Zip + 4","zip":"Property Zip Code","streetNum":"Property House Number"}', NULL, '{}', 'county', 'tax');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'parcel_id', 2, true, '"Assessor’s Parcel Number"', NULL, '{"stripFormatting":true}', 'county', 'tax');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'price', 3, false, '"Latest Sale - Price"', NULL, '{"nullZero":true}', 'county', 'tax');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'close_date', 4, false, '"Latest Sale - Recording Date"', NULL, '{}', 'county', 'tax');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'data_source_uuid', 5, true, '{"batchid":"FIPS Code","batchseq":"BKFS Internal PID"}', NULL, '{}', 'county', 'tax');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'fips_code', 6, true, '"FIPS Code"', NULL, '{}', 'county', 'tax');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'bedrooms', 7, false, '"Number of Bedrooms"', NULL, '{}', 'county', 'tax');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'baths_full', 8, false, '"Number of Baths"', NULL, '{}', 'county', 'tax');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'acres', 9, false, '"Lot Size - Acres"', NULL, '{}', 'county', 'tax');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'sqft_finished', 10, false, '"Main Building Area"', NULL, '{}', 'county', 'tax');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'owner_name', 11, true, '{"first":"Owner1FirstName","last":"Owner1LastName","middle":"Owner1MiddleName","full":"Current Owner Name"}', NULL, '{}', 'county', 'tax');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'owner_name_2', 12, true, '{"first":"Owner2Firstname","last":"Owner2LastName","middle":"Owner2MiddleName"}', NULL, '{}', 'county', 'tax');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'rm_property_id', 0, true, '{"fipsCode":"FIPS Code","apn":"Assessor’s Parcel Number"}', NULL, '{}', 'county', 'mortgage');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'address', 1, false, '{"city":"Property City Name","streetFull":"Property Full Street Address","streetNum":"Property House Number","state":"Property State","streetDirPrefix":"Property Street Direction Left","streetDirSuffix":"Property Street Direction Right","streetName":"Property Street Name","streetSuffix":"Property Street Suffix","unitNum":"Property Unit Number","zip9":"Property Zip + 4","zip":"Property Zip Code"}', NULL, '{}', 'county', 'mortgage');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'parcel_id', 2, true, '"Assessor’s Parcel Number"', NULL, '{"stripFormatting":true}', 'county', 'mortgage');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'price', 3, false, '"Current Sale - Price"', NULL, '{"nullZero":true}', 'county', 'mortgage');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'close_date', 4, false, '"Current Sale - Recording Date"', NULL, '{}', 'county', 'mortgage');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'data_source_uuid', 5, true, '{"batchid":"FIPS Code","batchseq":"BKFS Internal PID"}', NULL, '{}', 'county', 'mortgage');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'fips_code', 6, true, '"FIPS Code"', NULL, '{}', 'county', 'mortgage');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'owner_name', 7, true, '{"first":"#1 - Borrower First Name & Middle Name","last":"#1 - Borrower Last Name OR Corporation Name"}', NULL, '{}', 'county', 'mortgage');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'owner_name_2', 8, true, '{"first":"#2 - Borrower First Name & Middle Name","last":"#2 - Borrower Last Name OR Corporation Name"}', NULL, '{}', 'county', 'mortgage');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'address', 1, false, '{"city":"Property City Name","streetFull":"Property Full Street Address","streetNum":"Property House Number","state":"Property State","streetDirPrefix":"Property Street Direction Left","streetDirSuffix":"Property Street Direction Right","streetName":"Property Street Name","streetSuffix":"Property Street Suffix","unitNum":"Property Unit Number","zip9":"Property Zip + 4","zip":"Property Zip Code"}', NULL, '{}', 'county', 'deed');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'close_date', 4, false, '"Recording Date"', NULL, '{}', 'county', 'deed');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'data_source_uuid', 5, true, '{"batchid":"FIPS Code","batchseq":"BKFS Internal PID"}', NULL, '{}', 'county', 'deed');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'fips_code', 6, true, '"FIPS Code"', NULL, '{}', 'county', 'deed');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'owner_name', 7, true, '{"first":"#1 - Buyer First Name & Middle Name","last":"#1 - Buyer Last Name OR Corporation Name"}', NULL, '{}', 'county', 'deed');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'owner_name_2', 8, true, '{"first":"#2 - Buyer First Name & Middle Name","last":"#2 - Buyer Last Name OR Corporation Name"}', NULL, '{}', 'county', 'deed');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'parcel_id', 2, true, '"Assessor’s Parcel Number"', NULL, '{"stripFormatting":true}', 'county', 'deed');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'price', 3, false, '"Sales Price"', NULL, '{"nullZero":true}', 'county', 'deed');
INSERT INTO config_data_normalization (data_source_id, list, output, ordering, required, input, transform, config, data_source_type, data_type) VALUES ('blackknight', 'base', 'rm_property_id', 0, true, '{"fipsCode":"FIPS Code","apn":"Assessor’s Parcel Number"}', NULL, '{}', 'county', 'deed');

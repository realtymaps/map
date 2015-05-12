DROP TABLE IF EXISTS data_normalization_config;
CREATE TABLE data_normalization_config (
  data_source_id TEXT NOT NULL,
  data_source_type TEXT NOT NULL,
  output_blob_name TEXT NOT NULL,
  output_column_name TEXT NOT NULL,
  input JSON,
  validation TEXT,
  required BOOLEAN NOT NULL DEFAULT FALSE
);

INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', 'rm-core', 'fips_code', '"County Or Parish"', $$
  validators.fips(states: ['FL'])
$$, TRUE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Acres', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', 'hidden', 'Active Open House Count', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Additional Rooms', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Amenities', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Amenity Rec Fee', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Amen Rec Freq', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Application Fee', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Approval', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Approx Living Area', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Association Mngmt Phone', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Baths Full', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Baths Half', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Baths Total', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Bedroom Desc', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Bedrooms', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Beds Total', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Block', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Blogging YN', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Boat Access', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Builder Product YN', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Building Desc', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Building Design', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Building Number', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Cable Available YN', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Canal Width', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Carport Desc', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Carport Spaces', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'CDOM', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'City', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Close Date', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Close Price', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Co List Agent MUI', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Co List Agent Full Name', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Co List Office MUI', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Co List Office MLSID', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Co List Office Name', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Co List Office Phone', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Community Type', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Conditional Date', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Condo Fee', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Condo Fee Freq', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Construction', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Cooling', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'County Or Parish', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Created Date', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Current Price', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Development', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Development Name', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Dining Description', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'DOM', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Elementary School', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Elevator', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Equipment', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Exterior Features', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Exterior Finish', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Flooring', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Floor Plan Type', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Foreclosed REOYN', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Full Address', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Furnished Desc', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Garage Desc', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Garage Dimension', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Garage Spaces', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Guest House Desc', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Guest House Living Area', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Gulf Access Type', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Gulf Access YN', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Heat', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'High School', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'HOA Desc', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'HOA Fee', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'HOA Fee Freq', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Interior Features', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Internet Sites', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Irrigation', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Kitchen Description', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Land Lease Fee', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Land Lease Fee Freq', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Last Change Timestamp', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Last Change Type', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Lease Limits YN', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Leases Per Year', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Legal Desc', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Legal Unit', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'List Agent MUI', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'List Agent Direct Work Phone', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'List Agent Full Name', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'List Agent MLSID', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Listing On Internet YN', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'List Office MUI', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'List Office MLSID', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'List Office Name', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'List Office Phone', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'List Price', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Lot Back', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Lot Desc', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Lot Frontage', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Lot Left', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Lot Right', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Lot Unit', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Maintenance', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Management', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Mandatory Club Fee', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Mandatory Club Fee Freq', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Mandatory HOAYN', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Master Bath Description', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Master HOA Fee', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Master HOA Fee Freq', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Matrix Unique ID', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Matrix Modified DT', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Middle School', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Min Daysof Lease', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'MLS', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'MLS Area Major', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'MLS Number', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Numberof Ceiling Fans', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Num Unit Floor', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'One Time Land Lease Fee', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'One Time Mandatory Club Fee', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'One Time Othe Fee', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'One Time Rec Lease Fee', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'One Time Special Assessment Fee', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Original List Price', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Ownership Desc', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Parcel Number', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Parking', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Pets', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Pets Limit Max Number', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Pets Limit Max Weight', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Pets Limit Other', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Photo Count', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Photo Modification Timestamp', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Possession', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Postal Code', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Postal Code Plus 4', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Potential Short Sale YN', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Price Per Sq Ft', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Private Pool Desc', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Private Pool YN', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Private Spa Desc', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Private Spa YN', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Property Addresson Internet YN', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Property Information', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Property Type', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Range', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Rear Exposure', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Restrictions', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Road', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Roof', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Room Count', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Section', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Selling Agent MUI', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Selling Agent Full Name', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Selling Agent MLSID', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Selling Office MUI', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Selling Office MLSID', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Selling Office Name', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Selling Office Phone', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Sell Price Per Sq Ft', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Sewer', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Sourceof Measure Living Area', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Sourceof Measure Lot Dimensions', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Sourceof Measurements', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Sourceof Measure Total Area', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Special Assessment', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Special Assessment Fee Freq', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Special Information', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'State Or Province', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Status', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Status Type', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Storm Protection', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Street Dir Prefix', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Street Dir Suffix', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Street Name', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Street Number', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Street Number Modifier', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Street Suffix', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Sub Condo Name', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Subdivision Number', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Table', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Tax Desc', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Tax District Type', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Taxes', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Tax Year', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Total Area', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Total Floors', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Township', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Transfer Fee', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Unit Count', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Unit Floor', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Unit Number', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Unitsin Building', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Unitsin Complex', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'View', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Virtual Tour URL', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Water', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Waterfront Desc', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Waterfront YN', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Windows', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Year Built', '', $$

$$, FALSE);
INSERT INTO data_normalization_config VALUES ('swflmls', 'mls', '', 'Zoning Code', '', $$

$$, FALSE);

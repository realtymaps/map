DROP TABLE IF EXISTS data_normalization_config;
CREATE TABLE data_normalization_config (
  data_source_id TEXT NOT NULL,
  
  list TEXT NOT NULL,
  output TEXT,
  ordering INTEGER NOT NULL,
  
  required BOOLEAN NOT NULL,
  input JSON,
  transform TEXT
);
CREATE INDEX ON data_normalization_config (data_source_id, list ASC, ordering ASC);

CREATE OR REPLACE FUNCTION easy_normalization_insert (_data_source_id TEXT, _list TEXT, _output TEXT, _required BOOLEAN, _input JSON, _transform TEXT)
  RETURNS VOID AS $$
  BEGIN
    INSERT INTO data_normalization_config VALUES (
      _data_source_id, 
      _list, 
      _output, 
      (SELECT COUNT(*) FROM data_normalization_config WHERE data_source_id = _data_source_id AND list = _list), 
      _required,
      _input,
      _transform
    );
  END;
  $$
LANGUAGE plpgsql;

SELECT easy_normalization_insert ('swflmls', 'base', 'rm_property_id', TRUE, '["County Or Parish", "Parcel Number"]', $$
  validators.rm_property_id({state: 'FL'})
$$);
SELECT easy_normalization_insert ('swflmls', 'base', 'fips_code', TRUE, '"County Or Parish"', $$
  validators.fips({state: 'FL'})
$$);
SELECT easy_normalization_insert ('swflmls', 'base', 'parcel_id', TRUE, '"Parcel Number"', $$
  validators.string({stripFormatting: true})
$$);
SELECT easy_normalization_insert ('swflmls', 'base', 'address', TRUE, $${
  "streetNum": "Street Number",
  "streetName": "Street Name",
  "city": "City",
  "state": "State Or Province",
  "zip": "Postal Code",
  "zip9": "Postal Code Plus 4",
  "streetDirPrefix": "Street Dir Prefix",
  "streetDirSuffix": "Street Dir Suffix",
  "streetSuffix": "Street Suffix",
  "streetNumSuffix": "Street Number Modifier",
  "streetFull": "Full Address",
  "unitNum": "Unit Number"
}$$, $$
  validators.address()
$$);
SELECT easy_normalization_insert ('swflmls', 'base', 'price', TRUE, '"Current Price"', $$
  validators.currency()
$$);
SELECT easy_normalization_insert ('swflmls', 'base', 'days_on_market', TRUE, '["CDOM", "DOM"]', $$
  validators.pickFirst({criteria: validators.integer()})
$$);
SELECT easy_normalization_insert ('swflmls', 'base', 'bedrooms', TRUE, '"Beds Total"', $$
  validators.integer()
$$);
SELECT easy_normalization_insert ('swflmls', 'base', 'baths_full', TRUE, '"Baths Full"', $$
  validators.integer()
$$);
SELECT easy_normalization_insert ('swflmls', 'base', 'acres', TRUE, '"Acres"', $$
  validators.float() 
$$);
SELECT easy_normalization_insert ('swflmls', 'base', 'sqft_finished', TRUE, '"Approx Living Area"', $$
  validators.integer()
$$);
SELECT easy_normalization_insert ('swflmls', 'base', 'status', TRUE, '"Status"', $$
  validators.choice({choices: {
    'Active': 'for sale',
    'Pending': 'pending',
    'Pending w/ Contingent': 'pending',
    'Closed': 'sold',
    'Terminated': 'not for sale',
    'Expired': 'not for sale',
    'Withdrawn': 'not for sale'
  }})
$$);
SELECT easy_normalization_insert ('swflmls', 'base', 'substatus', TRUE, '"Status"', $$
  validators.choice({choices: {
    'Active': 'for sale',
    'Pending': 'pending',
    'Pending w/ Contingent': 'pending-contingent',
    'Closed': 'sold',
    'Terminated': 'terminated',
    'Expired': 'expired',
    'Withdrawn': 'withdrawn'
  }})
$$);
SELECT easy_normalization_insert ('swflmls', 'base', 'status_display', TRUE, '"Status"', NULL);
SELECT easy_normalization_insert ('swflmls', 'base', 'hide_address', TRUE, '"Property Addresson Internet YN"', $$
  validators.boolean({invert: true})
$$);



SELECT easy_normalization_insert ('swflmls', 'hidden', 'Listing On Internet YN', TRUE, NULL, $$
  validators.nullify(value: false)
$$);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Property Addresson Internet YN', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Active Open House Count', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Baths Total', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Bedrooms', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Internet Sites', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'MLS', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Photo Count', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Photo Modification Timestamp', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Table', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Virtual Tour URL', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Blogging YN', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Co List Office MUI', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Co List Office MLSID', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Co List Agent MUI', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'List Agent MUI', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'List Agent MLSID', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'List Office MUI', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'List Office MLSID', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Selling Agent MUI', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Selling Agent MLSID', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Selling Office MUI', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Selling Office MLSID', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'hidden', 'Current Price', FALSE, NULL, NULL);



SELECT easy_normalization_insert ('swflmls', 'general', 'List Price', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'general', 'Conditional Date', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'general', 'Close Date', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'general', 'Close Price', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'general', 'status', TRUE, '"Status"', $$
  validators.choice({choices: {
    'Active': 'for sale',
    'Pending': 'pending',
    'Pending w/ Contingent': 'pending',
    'Closed': 'sold',
    'Terminated': 'not for sale',
    'Expired': 'not for sale',
    'Withdrawn': 'not for sale'
  }})
$$);
SELECT easy_normalization_insert ('swflmls', 'general', 'address', TRUE, $${
  "streetNum": "Street Number",
  "streetName": "Street Name",
  "city": "City",
  "state": "State Or Province",
  "zip": "Postal Code",
  "zip9": "Postal Code Plus 4",
  "streetDirPrefix": "Street Dir Prefix",
  "streetDirSuffix": "Street Dir Suffix",
  "streetSuffix": "Street Suffix",
  "streetNumSuffix": "Street Number Modifier",
  "streetFull": "Full Address",
  "unitNum": "Unit Number"
}$$, $$
  validators.address()
$$);
SELECT easy_normalization_insert ('swflmls', 'general', 'Acres', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'general', 'Approx Living Area', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'general', 'Total Area', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'general', 'Price Per Sq Ft', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'general', 'Sell Price Per Sq Ft', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'general', 'DOM', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'general', 'CDOM', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'general', 'Baths Full', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'general', 'Baths Half', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'general', 'Beds Total', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'general', 'Year Built', FALSE, NULL, NULL);



SELECT easy_normalization_insert ('swflmls', 'details', 'Property Information', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Furnished Desc', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Building Design', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Ownership Desc', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Amenities', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Guest House Desc', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Guest House Living Area', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Room Count', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Kitchen Description', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Dining Desc', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Bedroom Desc', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Master Bath Description', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Equipment', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Flooring', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Numberof Ceiling Fans', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Cooling', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Heat', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Interior Features', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Exterior Features', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Parking', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Storm Protection', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Community Type', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Floor Plan Type', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Additional Rooms', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Private Pool Desc', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Private Pool YN', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Private Spa Desc', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Private Spa YN', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Cable Available YN', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Management', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'Maintenance', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'details', 'View', FALSE, NULL, NULL);



SELECT easy_normalization_insert ('swflmls', 'listing', 'Created Date', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'listing', 'Original List Price', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'listing', 'Last Change Timestamp', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'listing', 'Last Change Type', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'listing', 'Status Type', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'listing', 'Property Type', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'listing', 'Foreclosed REOYN', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'listing', 'Potential Short Sale YN', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'listing', 'Possession', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'listing', 'Sourceof Measure Living Area', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'listing', 'Sourceof Measure Lot Dimensions', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'listing', 'Sourceof Measurements', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'listing', 'Sourceof Measure Total Area', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'listing', 'Special Information', FALSE, NULL, NULL);


SELECT easy_normalization_insert ('swflmls', 'building', 'Building Desc', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Building Number', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Carport Desc', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Carport Spaces', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Construction', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Elevator', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Garage Desc', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Garage Dimensions', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Garage Spaces', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Roof', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Builder Product YN', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Exterior Finish', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Windows', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Num Unit Floor', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Total Floors', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Unit Count', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Unit Floor', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Unitsin Building', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'building', 'Unitsin Complex', FALSE, NULL, NULL);


SELECT easy_normalization_insert ('swflmls', 'lot', 'Parcel Number', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Lot Desc', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Lot Frontage', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Lot Back', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Lot Left', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Lot Right', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Rear Exposure', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Gulf Access YN', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Gulf Access Type', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Boat Access', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Canal Width', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Waterfront Desc', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Waterfront YN', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Irrigation', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Legal Desc', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Legal Unit', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Lot Unit', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Road', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Sewer', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Water', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'lot', 'Zoning Code', FALSE, NULL, NULL);


SELECT easy_normalization_insert ('swflmls', 'location', 'MLS Area Major', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'location', 'County Or Parish', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'location', 'Development', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'location', 'Development Name', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'location', 'Sub Condo Name', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'location', 'Subdivision Number', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'location', 'Elementary School', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'location', 'Middle School', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'location', 'High School', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'location', 'Block', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'location', 'Range', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'location', 'Section', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'location', 'Township', FALSE, NULL, NULL);


SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Restrictions', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Approval', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Pets', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Pets Limit Max Number', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Pets Limit Max Weight', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Pets Limit Other', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Min Daysof Lease', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Lease Limits YN', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Leases Per Year', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Amenity Rec Fee', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Amen Rec Freq', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Application Fee', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Condo Fee', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Condo Fee Freq', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Mandatory HOAYN', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'HOA Desc', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'HOA Fee', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'HOA Fee Freq', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Master HOA Fee', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Master HOA Fee Freq', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Association Mngmt Phone', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Land Lease Fee', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Land Lease Fee Freq', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Mandatory Club Fee', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Mandatory Club Fee Freq', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'One Time Land Lease Fee', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'One Time Mandatory Club Fee', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'One Time Othe Fee', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'One Time Rec Lease Fee', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'One Time Special Assessment Fee', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Special Assessment', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Special Assessment Fee Freq', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Tax Desc', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Tax District Type', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Taxes', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Tax Year', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'restrictions', 'Transfer Fee', FALSE, NULL, NULL);



SELECT easy_normalization_insert ('swflmls', 'contacts', 'List Agent Full Name', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'contacts', 'List Agent Direct Work Phone', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'contacts', 'List Office Name', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'contacts', 'List Office Phone', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'contacts', 'Co List Agent Full Name', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'contacts', 'Co List Office Name', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'contacts', 'Co List Office Phone', FALSE, NULL, NULL);


SELECT easy_normalization_insert ('swflmls', 'realtor', 'Matrix Unique ID', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'realtor', 'Matrix Modified DT', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'realtor', 'MLS Number', FALSE, NULL, NULL);


SELECT easy_normalization_insert ('swflmls', 'sale', 'Selling Agent Full Name', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'sale', 'Selling Office Name', FALSE, NULL, NULL);
SELECT easy_normalization_insert ('swflmls', 'sale', 'Selling Office Phone', FALSE, NULL, NULL);


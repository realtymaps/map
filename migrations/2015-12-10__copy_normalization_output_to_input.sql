UPDATE config_data_normalization
SET input = ('"' || output || '"')::JSON
WHERE list != 'base';

UPDATE config_data_normalization
SET input = replace(input::TEXT, 'apnUnformatted', 'apn')::JSON;

UPDATE config_data_normalization
SET input = replace(input::TEXT, 'apnSequence', 'sequenceNumber')::JSON;

UPDATE config_data_normalization
SET input = replace(input::TEXT, 'parcelId', 'apn')::JSON;


DELETE FROM config_data_normalization WHERE data_type = 'agent';
INSERT INTO config_data_normalization ("data_source_id","list","output","ordering","required","input","transform","config","data_source_type","data_type")
VALUES
  (E'swflmls',E'base',E'agent_status',2,TRUE,E'"Agent Status"',NULL,E'{"nullEmpty":true,"trim":true,"mapping":{"Active":"active","Inactive":"inactive"}}',E'mls',E'agent'),
  (E'swflmls',E'base',E'data_source_uuid',5,TRUE,E'"Matrix Unique ID"',NULL,E'{"nullEmpty":true,"trim":true}',E'mls',E'agent'),
  (E'swflmls',E'base',E'email',3,FALSE,E'"Email"',NULL,E'{"nullEmpty":true,"trim":true}',E'mls',E'agent'),
  (E'swflmls',E'base',E'full_name',1,TRUE,E'{"full":"Full Name","first":"First Name","middle":"Middle Name","last":"Last Name","suffix":"Generational Name"}',NULL,E'{}',E'mls',E'agent'),
  (E'swflmls',E'base',E'license_number',0,TRUE,E'"License Number"',NULL,E'{"nullEmpty":true,"trim":true}',E'mls',E'agent'),
  (E'swflmls',E'base',E'work_phone',4,FALSE,E'"Direct Work Phone"',NULL,E'{"nullEmpty":true,"trim":true}',E'mls',E'agent');

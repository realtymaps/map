INSERT INTO "config_data_normalization"("data_source_id","list","output","ordering","required","input","transform","config","data_source_type","data_type")
VALUES
  (E'swflmls',E'base',E'parcel_id',1000,TRUE,E'"Parcel Number"',NULL,E'{"stripFormatting":true,"nullEmpty":true,"trim":true}',E'mls',E'listing'),
  (E'swflmls',E'base',E'photo_last_mod_time',1022,TRUE,E'"Photo Modification Timestamp"',NULL,E'{}',E'mls',E'listing');

ALTER TABLE data_combined ADD COLUMN description TEXT;
ALTER TABLE data_combined ADD COLUMN original_price NUMERIC;

update config_data_normalization set list='hidden', ordering=23 where data_source_id='swflmls' and output='Property Information';
update config_data_normalization set list='hidden', ordering=24 where data_source_id='swflmls' and output='Original List Price';
update config_data_normalization set list='hidden', ordering=44 where data_source_id='MRED' and output='Remarks';
update config_data_normalization set list='hidden', ordering=45 where data_source_id='MRED' and output='Original List Price';

INSERT INTO "config_data_normalization"("data_source_id","list","output","ordering","required","input","transform","config","data_source_type","data_type")
VALUES
(E'swflmls',E'base',E'description',23,FALSE,E'"Property Information"',NULL,E'{"nullEmpty":true}',E'mls',E'listing'),
(E'swflmls',E'base',E'original_price',24,FALSE,E'"Original List Price"',NULL,E'{"nullZero":true}',E'mls',E'listing'),
(E'MRED',E'base',E'original_price',24,FALSE,E'"Original List Price"',NULL,E'{"nullZero":true}',E'mls',E'listing'),
(E'MRED',E'base',E'description',23,FALSE,E'"Remarks"',NULL,E'{"nullEmpty":true}',E'mls',E'listing');

SELECT f_add_col('data_combined', 'photo_import_error', 'text');

ALTER TABLE data_combined
	ADD COLUMN id bigserial NOT NULL;
ALTER TABLE data_combined ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;

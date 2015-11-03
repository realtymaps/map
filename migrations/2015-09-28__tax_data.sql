ALTER TABLE normal_tax_data ADD COLUMN prior_price NUMERIC;
ALTER TABLE normal_tax_data ADD COLUMN prior_close_date TIMESTAMP;
ALTER TABLE normal_tax_data ADD COLUMN prior_parcel_id TEXT;
ALTER TABLE normal_tax_data ADD COLUMN prior_owner_name TEXT;
ALTER TABLE normal_tax_data ADD COLUMN prior_owner_name_2 TEXT;

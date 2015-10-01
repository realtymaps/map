
CREATE INDEX ON normal_tax_data (batch_id);
CREATE INDEX ON normal_deed_data (batch_id);
CREATE INDEX ON normal_listing_data (batch_id);

CREATE INDEX ON normal_tax_data (rm_property_id, deleted, close_date DESC NULLS FIRST);
CREATE INDEX ON normal_deed_data (rm_property_id, deleted, close_date DESC NULLS FIRST);

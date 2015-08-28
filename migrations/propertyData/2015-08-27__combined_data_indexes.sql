
-- these indexes were naiive / aggressive, and slow down insert/update/delete operations without helping
DROP INDEX IF EXISTS combined_data_geometry_raw_idx;
DROP INDEX IF EXISTS combined_data_price_idx;
DROP INDEX IF EXISTS combined_data_close_date_idx;
DROP INDEX IF EXISTS combined_data_days_on_market_idx;
DROP INDEX IF EXISTS combined_data_bedrooms_idx;
DROP INDEX IF EXISTS combined_data_baths_full_idx;
DROP INDEX IF EXISTS combined_data_acres_idx;
DROP INDEX IF EXISTS combined_data_sqft_finished_idx;
DROP INDEX IF EXISTS combined_data_status_idx;
DROP INDEX IF EXISTS combined_data_owner_name_idx;
DROP INDEX IF EXISTS combined_data_owner_name_2_idx;
DROP INDEX IF EXISTS combined_data_active_idx;
DROP INDEX IF EXISTS combined_data_data_source_type_idx;
-- not deleted were the indexes individually on rm_property_id and data_source_id


-- these 2 indexes are specifically targeted for expected use cases; we might add more when we are using this table
-- for real and can test what actually helps
CREATE INDEX ON combined_data USING GIST (geometry_raw) WHERE active IS TRUE;
CREATE INDEX ON combined_data (active, data_source_id);



-- these are redundant indexes
DROP INDEX IF EXISTS jq_subtask_config_name_idx;
DROP INDEX IF EXISTS combined_data_data_source_id_idx1;

-- these indexes will be superseded by new ones below
DROP INDEX IF EXISTS combined_data_rm_property_id_idx;


-- existing data_combined indexes we're keeping (for reference)
/*
CREATE INDEX ON data_combined (data_source_id);
CREATE INDEX ON data_combined USING GIST (geometry_raw) WHERE active IS TRUE;
CREATE INDEX ON data_combined (active, data_source_id);
CREATE INDEX ON data_combined (data_source_id, rm_property_id, update_source, batch_id)
  WHERE active = FALSE;
CREATE INDEX ON data_combined USING gin (photos);
*/


-- new filter used when finalizing and activating rows into data_combined
CREATE INDEX ON data_combined (rm_property_id, data_source_id) WHERE active IS FALSE;

-- new filter indexes for data_combined
CREATE INDEX ON data_combined (rm_property_id) WHERE active IS TRUE;
CREATE INDEX ON data_combined (fips_code) WHERE active IS TRUE;
CREATE INDEX ON data_combined (status) WHERE active IS TRUE;
CREATE INDEX ON data_combined (close_date) WHERE active IS TRUE;
CREATE INDEX ON data_combined (property_type) WHERE active IS TRUE;
CREATE INDEX ON data_combined (price) WHERE active IS TRUE;
CREATE INDEX ON data_combined (bedrooms) WHERE active IS TRUE;
CREATE INDEX ON data_combined (baths_total) WHERE active IS TRUE;

ANALYZE;


DROP INDEX listing_batch_id_idx;
CREATE INDEX ON listing (batch_id, data_source_id);

DROP INDEX listing_rm_property_id_deleted_hide_listing_close_date_idx;
CREATE INDEX ON listing (rm_property_id, hide_listing, data_source_id, deleted, close_date DESC NULLS FIRST);


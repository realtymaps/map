UPDATE view_definitions
SET definition = 'parcel_status3(mls.status, mls.rm_property_id IS NOT NULL, mls.close_date::DATE, tax.sale_date::DATE, deed.sale_date::DATE, tax.prior_sale_date::DATE, ''2 months'', ''2014-04-16''::DATE)'
WHERE name = 'rm_status' AND view_id = 'property_details_main';

SELECT dirty_materialized_view('property_details', FALSE);
SELECT stage_dirty_views();
SELECT push_staged_views(FALSE);

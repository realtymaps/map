ALTER TABLE parcels DROP CONSTRAINT parcels_pkey;
ALTER TABLE parcels DROP COLUMN id;

SELECT dirty_materialized_view('parcels', FALSE);

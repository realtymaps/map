ALTER TABLE parcels DROP CONSTRAINT IF EXISTS parcels_pkey;
ALTER TABLE parcels DROP COLUMN IF EXISTS id;

SELECT dirty_materialized_view('parcels', FALSE);

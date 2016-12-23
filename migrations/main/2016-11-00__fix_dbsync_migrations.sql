
-- change existing migrations from 12_34_5678 style to 12-34-5678 style for consistency
UPDATE dbsync_migrations
SET migration_id = substring(migration_id from 1 for 4) || '-' || substring(migration_id from 6 for 2) || '-' || substring(migration_id from 9)
WHERE substring(migration_id from 5 for 1) = '_';

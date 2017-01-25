
-- PLEASE keep consistent migration naming conventions, not doing so can lead to problems with migration order

-- change existing migrations from 12_34_5678 style to 12-34-5678 style for consistency
UPDATE dbsync_migrations
SET migration_id = substring(migration_id from 1 for 4) || '-' || substring(migration_id from 6 for 2) || '-' || substring(migration_id from 9)
WHERE substring(migration_id from 5 for 1) = '_';

-- when rerunning this migration, the follow command line will fix the files themselves:
-- pushd ./migrations/main && for f in `ls 201?_*`; do echo "fixing $f" && mv "$f" "${f:0:4}-${f:5:2}-${f:8}"; done && popd

ALTER TABLE dbsync_migrations
  ADD COLUMN lines_completed INTEGER,
  ADD COLUMN commands_completed INTEGER,
  ADD COLUMN error_command TEXT,
  ADD COLUMN error_message TEXT
;

UPDATE dbsync_migrations SET filename = regexp_replace(filename, '(\d)_(\d)', E'\\1-\\2', 'g') WHERE filename ~ '...._.._..__.*';

ALTER TABLE dbsync_migrations RENAME COLUMN filename TO migration_id;

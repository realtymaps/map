

-- remove the data itself
DELETE FROM data_combined where data_source_type = 'county';


-- one-time bootstrap needed here; delete this before re-using this migration
INSERT INTO config_keystore (namespace, key, value)
VALUES
  ('blackknight process dates finished', 'Update', '["20160824","20160829"]'),
  ('blackknight process dates finished', 'Refresh', '["20160824","20160829"]');


-- move the already-processed dates back into the queue
UPDATE
  config_keystore AS ck
SET
  value = ck.value::JSONB || ck_finished.value::JSONB
FROM
  config_keystore AS ck_finished
WHERE
  ck.namespace = 'blackknight process dates' AND
  ck_finished.namespace = 'blackknight process dates finished' AND
  ck.key = ck_finished.key;
DELETE FROM config_keystore WHERE namespace = 'blackknight process dates finished';


-- leave the line below commented out unless we need to re-copy the files to S3
-- DELETE FROM config_keystore WHERE namespace = 'blackknight copy dates';

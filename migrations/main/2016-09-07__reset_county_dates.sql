
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

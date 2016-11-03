
-- move the already-processed dates back into the queue
UPDATE
  config_keystore AS ck
SET
  value = ck.value::JSONB || ck_finished.value::JSONB
FROM
  config_keystore AS ck_finished
WHERE
  ck.namespace = 'blackknight process info' AND
  ck_finished.namespace = 'blackknight process info' AND
  ck.key = 'dates queued' AND
  ck_finished.key = 'dates completed';

-- remove bad or distracting values
UPDATE config_keystore
SET value = '[]'::JSON
WHERE
  namespace = 'blackknight process info' AND
  key IN (
    'fips queued',
    'dates completed',
    'current process date',
    'delete batch_id'
  );

DELETE FROM config_keystore
WHERE namespace = 'blackknight process dates' or namespace = 'blackknight copy dates';

INSERT INTO config_keystore (namespace, key, value)
VALUES
  ('blackknight process dates', 'Update', '[]'),
  ('blackknight process dates', 'Refresh', '[]'),
  ('blackknight copy dates', 'Update', '"20160823"'),
  ('blackknight copy dates', 'Refresh', '"20160823"'),
  ('blackknight copy dates', 'no new data found', '"19700101"');


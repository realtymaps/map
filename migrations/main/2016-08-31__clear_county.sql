
-- remove the data itself
DELETE FROM data_combined where data_source_type = 'county';


-- the below update shouldn't be needed in the future, this is just to patch the data due to a code bug
UPDATE config_keystore
SET value = '["20160824","20160829","20160830"]'
WHERE namespace = 'blackknight process dates finished';


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

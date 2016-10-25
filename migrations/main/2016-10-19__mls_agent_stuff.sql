
UPDATE jq_task_config
SET name = '<mls_id>_listings'
WHERE name = '<default_mls_config>';

UPDATE jq_subtask_config
SET
  task_name = '<mls_id>_listings'
  name = replace(name, '<default_mls_config>', '<mls_id>_listings')
WHERE task_name = '<default_mls_config>';


UPDATE jq_task_config
SET name = '<mls_id>_photos'
WHERE name = '<default_mls_photos_config>';

UPDATE jq_subtask_config
SET
  task_name = '<mls_id>_photos'
  name = replace(name, '<default_mls_photos_config>', '<mls_id>_photos')
WHERE task_name = '<default_mls_photos_config>';



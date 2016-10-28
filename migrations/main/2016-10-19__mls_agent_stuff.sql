
-- change the mls listings task config

UPDATE jq_task_config
SET name = '<mlsid>'
WHERE name = '<default_mls_config>';

UPDATE jq_task_config
SET
  name = name||'_listing',
  blocked_by_tasks = ('["'||name||'_photo","'||name||'_agent"]')::JSONB
WHERE description = 'Refresh mls data';


-- change the mls photos task config

UPDATE jq_task_config
SET name = '<mlsid>_photo'
WHERE name = '<default_mls_photos_config>';

UPDATE jq_task_config
SET
  blocked_by_tasks = ('["'||replace(name,'_photos','_listing')||'","'||replace(name,'_photos','_agent')||'"]')::JSONB,
  name = replace(name,'_photos','_photo')
WHERE name LIKE '%\_photos';


-- change the subtasks to match

UPDATE jq_subtask_config
SET
  task_name = '<mlsid>_listing',
  name = replace(name, '<default_mls_config>', '<mlsid>_listing')
WHERE task_name = '<default_mls_config>';

UPDATE jq_subtask_config
SET
  task_name = task_name||'_listing',
  name = replace(name, task_name||'_', task_name||'_listing_')
WHERE
  queue_name = 'mls'
  AND task_name NOT LIKE '%\_%'
  AND task_name NOT LIKE '<%';

UPDATE jq_subtask_config
SET
  task_name = '<mlsid>_photo',
  name = replace(name, '<default_mls_photos_config>', '<mlsid>_photo')
WHERE task_name = '<default_mls_photos_config>';

UPDATE jq_subtask_config
SET
  task_name = replace(task_name,'_photos','_photo'),
  name = replace(name,'_photos_','_photo_')
WHERE
  queue_name = 'mls'
  AND task_name LIKE '%\_photos'
  AND task_name NOT LIKE '<%';


-- remove unneeded data

UPDATE jq_subtask_config
SET data = NULL
WHERE
  queue_name = 'mls'
  AND name LIKE '%\_loadRawData';

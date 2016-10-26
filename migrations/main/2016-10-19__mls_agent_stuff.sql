
-- change the mls listings task config

UPDATE jq_task_config
SET name = '<mlsid>'
WHERE name = '<default_mls_config>';

UPDATE jq_task_config
SET
  name = name||'_listings',
  blocked_by_tasks = ('["'||name||'_photos","'||name||'_agents"]')::JSONB
WHERE description = 'Refresh mls data';


-- change the mls photos task config

UPDATE jq_task_config
SET name = '<mlsid>_photos'
WHERE name = '<default_mls_photos_config>';

UPDATE jq_task_config
SET blocked_by_tasks = ('["'||replace(name,'_photos','_listings')||'","'||replace(name,'_photos','_agents')||'"]')::JSONB
WHERE description = 'Load MLS photos';


-- change the subtasks to match

UPDATE jq_subtask_config
SET
  task_name = '<mlsid>_listings',
  name = replace(name, '<default_mls_config>', '<mlsid>_listings')
WHERE task_name = '<default_mls_config>';

UPDATE jq_subtask_config
SET
  task_name = task_name||'_listings',
  name = replace(name, task_name||'_', task_name||'_listings_')
WHERE
  queue_name = 'mls'
  AND task_name NOT LIKE '%_%'
  AND task_name NOT LIKE '<%';

UPDATE jq_subtask_config
SET
  task_name = '<mlsid>_photos'
  name = replace(name, '<default_mls_photos_config>', '<mlsid>_photos')
WHERE task_name = '<default_mls_photos_config>';

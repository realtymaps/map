
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


-- new task and subtasks

INSERT INTO jq_task_config ("name","description","data","ignore_until","repeat_period_minutes","warn_timeout_minutes","kill_timeout_minutes","active","fail_retry_minutes","blocked_by_tasks","blocked_by_locks")
VALUES
  (E'<mlsid>_agent',E'Load MLS agents',E'{}',NULL,1440,15,NULL,FALSE,1,E'["<mlsid>_listing", "<mlsid>_photo"]',E'[]'),
  (E'swflmls_agent',E'Load MLS agents',E'{}',NULL,1440,15,NULL,TRUE,1,E'["swflmls_listing", "swflmls_photo"]',E'[]'),
  (E'RAPB_agent',E'Load MLS agents',E'{}',NULL,1440,15,NULL,TRUE,1,E'["RAPB_listing", "RAPB_photo"]',E'[]');
INSERT INTO jq_subtask_config ("name","task_name","queue_name","data","step_num","retry_max_count","auto_enqueue","active","retry_delay_minutes","kill_timeout_minutes","warn_timeout_minutes")
VALUES
  (E'<mlsid>_agent_loadRawData',E'<mlsid>_agent',E'mls',NULL,1,10,TRUE,TRUE,1,NULL,10),
  (E'<mlsid>_agent_normalizeData',E'<mlsid>_agent',E'mls',E'null',2,5,FALSE,TRUE,NULL,NULL,10),
  (E'<mlsid>_agent_recordChangeCounts',E'<mlsid>_agent',E'mls',NULL,10003,5,FALSE,TRUE,NULL,NULL,5),
  (E'<mlsid>_agent_finalizeDataPrep',E'<mlsid>_agent',E'mls',E'null',10004,5,FALSE,TRUE,NULL,NULL,5),
  (E'<mlsid>_agent_finalizeData',E'<mlsid>_agent',E'mls',NULL,10005,5,FALSE,TRUE,NULL,NULL,10),
  (E'<mlsid>_agent_activateNewData',E'<mlsid>_agent',E'mls',NULL,10006,5,FALSE,TRUE,NULL,NULL,4),
  (E'swflmls_agent_loadRawData',E'swflmls_agent',E'mls',NULL,1,10,TRUE,TRUE,1,NULL,10),
  (E'swflmls_agent_normalizeData',E'swflmls_agent',E'mls',E'null',2,5,FALSE,TRUE,NULL,NULL,10),
  (E'swflmls_agent_recordChangeCounts',E'swflmls_agent',E'mls',NULL,10003,5,FALSE,TRUE,NULL,NULL,5),
  (E'swflmls_agent_finalizeDataPrep',E'swflmls_agent',E'mls',E'null',10004,5,FALSE,TRUE,NULL,NULL,5),
  (E'swflmls_agent_finalizeData',E'swflmls_agent',E'mls',NULL,10005,5,FALSE,TRUE,NULL,NULL,10),
  (E'swflmls_agent_activateNewData',E'swflmls_agent',E'mls',NULL,10006,5,FALSE,TRUE,NULL,NULL,4),
  (E'RAPB_agent_loadRawData',E'RAPB_agent',E'mls',NULL,1,10,TRUE,TRUE,1,NULL,10),
  (E'RAPB_agent_normalizeData',E'RAPB_agent',E'mls',E'null',2,5,FALSE,TRUE,NULL,NULL,10),
  (E'RAPB_agent_recordChangeCounts',E'RAPB_agent',E'mls',NULL,10003,5,FALSE,TRUE,NULL,NULL,5),
  (E'RAPB_agent_finalizeDataPrep',E'RAPB_agent',E'mls',E'null',10004,5,FALSE,TRUE,NULL,NULL,5),
  (E'RAPB_agent_finalizeData',E'RAPB_agent',E'mls',NULL,10005,5,FALSE,TRUE,NULL,NULL,10),
  (E'RAPB_agent_activateNewData',E'RAPB_agent',E'mls',NULL,10006,5,FALSE,TRUE,NULL,NULL,4);


-- setting some mls config values

DELETE FROM config_mls WHERE id IN ('swflmls', 'RAPB');
INSERT INTO config_mls ("id","name","notes","listing_data","static_ip","data_rules","formal_name","disclaimer_text","disclaimer_logo","dmca_contact_name","dmca_contact_address","verify_overlap","agent_data")
VALUES
  (E'swflmls',E'Southwest Florida',E'test',E'{"db": "Property", "field": "LastChangeTimestamp", "table": "RES", "photoRes": {"width": "1024", "height": "768"}, "field_type": "DateTime", "largestPhotoObject": "XLargePhoto"}',TRUE,E'{"nullString":""}',E'Sunshine MLS (SWFLMLS)',NULL,NULL,NULL,NULL,TRUE,E'{"db": "Agent", "field": "MatrixModifiedDT", "table": "AGENT", "field_type": "DateTime"}'),
  (E'RAPB',E'Realtors Association of the Palm Beaches',E'',E'{"db": "Property", "field": "LIST_87", "table": "A", "field_type": "DateTime"}',FALSE,E'{}',NULL,NULL,NULL,NULL,NULL,TRUE,E'{"db": "ActiveAgent", "field": "", "table": "Agent", "field_type": ""}');

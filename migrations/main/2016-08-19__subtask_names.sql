update jq_subtask_config set name = replace(name, '_', '_photos_') where task_name like '%_photos' and task_name not like '<default_%';

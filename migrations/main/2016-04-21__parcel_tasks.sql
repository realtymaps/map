update jq_task_config set name='digimaps' where name='parcelUpdate';
update jq_subtask_config set data = '{"dataType":"parcel"}' where name = 'digimaps_loadRawData';

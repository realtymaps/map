update jq_subtask_config
set step_num=3
where queue_name = 'mls' and  name like '%_storePhotosPrep%';

update jq_subtask_config
set step_num=4
where queue_name = 'mls' and name like '%_storePhotos%' and name not like '%_storePhotosPrep%';

update jq_subtask_config
set step_num=5
where queue_name = 'mls' and name like '%_recordChangeCounts%';

update jq_subtask_config
set step_num=6
where queue_name = 'mls' and name like '%_finalizeDataPrep%';

update jq_subtask_config
set step_num=7
where queue_name = 'mls' and name like '%_finalizeData%' and name not like '%_finalizeDataPrep%';

update jq_subtask_config
set step_num=8
where queue_name = 'mls' and name like '%_activateNewData%';

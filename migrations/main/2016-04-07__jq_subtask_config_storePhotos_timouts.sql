update jq_subtask_config
  set
    warn_timeout_seconds=600,
    kill_timeout_seconds=750
where name like '%storePhotos%' and name not like '%storePhotosPrep%';

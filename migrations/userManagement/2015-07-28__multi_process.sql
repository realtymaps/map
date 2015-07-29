-- pool2 bug fixed, multiprocess away!
UPDATE jq_queue_config SET processes_per_dyno = '2';

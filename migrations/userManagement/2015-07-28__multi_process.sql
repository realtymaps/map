-- there seems to be a bug in pool2/knex which doesn't play well with multi-processing  :-(
-- https://github.com/myndzi/pool2/issues/13
UPDATE jq_queue_config SET processes_per_dyno = '2';

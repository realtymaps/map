
UPDATE jq_subtask_config
SET queue_name = 'misc'
WHERE task_name IN ('lob', 'lobCleanup', 'lobPayment', 'stripe', 'events');

DELETE FROM jq_queue_config
WHERE name IN ('lob', 'stripe', 'events');

/*
  to reverse:

UPDATE jq_subtask_config
SET queue_name = 'lob'
WHERE task_name IN ('lob', 'lobCleanup', 'lobPayment');

UPDATE jq_subtask_config
SET queue_name = 'stripe'
WHERE task_name = 'stripe';

UPDATE jq_subtask_config
SET queue_name = 'events'
WHERE task_name = 'events';


INSERT INTO "public"."jq_queue_config"("name","lock_id","processes_per_dyno","subtasks_per_process","priority_factor","active")
VALUES
  (E'events',998441378,5,3,1,TRUE),
  (E'lob',56225253,1,5,1,TRUE),
  (E'stripe',548519642,1,5,1,TRUE);

*/

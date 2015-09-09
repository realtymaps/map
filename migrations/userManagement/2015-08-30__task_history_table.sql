-- for some reason I had this unique on batch_id only, but it needs to be on name, batch_id
ALTER TABLE jq_task_history DROP CONSTRAINT IF EXISTS jq_task_history_batch_id_key;
ALTER TABLE jq_task_history ADD UNIQUE (name, batch_id);

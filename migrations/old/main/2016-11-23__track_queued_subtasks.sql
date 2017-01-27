
ALTER TABLE jq_task_history ADD COLUMN subtasks_queued INTEGER DEFAULT 0 NOT NULL;

UPDATE jq_task_history SET subtasks_queued = subtasks_created - subtasks_finished - subtasks_running - subtasks_preparing;

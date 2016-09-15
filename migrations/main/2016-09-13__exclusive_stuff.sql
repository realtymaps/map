ALTER TABLE jq_task_history
ADD COLUMN blocked_by_tasks JSONB NOT NULL DEFAULT '[]'::JSONB,
ADD COLUMN blocked_by_locks JSONB NOT NULL DEFAULT '[]'::JSONB;

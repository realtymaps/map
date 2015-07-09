ALTER TABLE jq_current_subtasks ADD COLUMN auto_enqueue BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE jq_subtask_error_history ADD COLUMN auto_enqueue BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE jq_subtask_error_history ADD COLUMN stack TEXT;

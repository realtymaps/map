CREATE INDEX jq_current_tasks_idx ON jq_task_history (current) WHERE current = TRUE;
CREATE INDEX jq_subtasks_finished_idx ON jq_current_subtasks (task_name, finished DESC NULLS LAST);
CREATE INDEX jq_subtasks_status_idx ON jq_current_subtasks (status);
CREATE INDEX jq_task_count_idx ON jq_current_subtasks (task_name, batch_id);
CREATE INDEX jq_current_tasks_idx ON jq_task_history (name);

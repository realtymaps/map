ALTER TABLE user_events_queue ADD COLUMN weekly_processed bool NOT NULL DEFAULT 'f';
ALTER TABLE user_events_queue ADD COLUMN monthly_processed bool NOT NULL DEFAULT 'f';

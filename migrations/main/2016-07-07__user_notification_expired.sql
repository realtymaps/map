ALTER TABLE user_notification_expired add column last_attempt_time TIMESTAMP WITHOUT TIME ZONE NOT NULL;
ALTER TABLE user_notification_queue alter column last_attempt_time type TIMESTAMP WITHOUT TIME ZONE;

ALTER TABLE user_notification_queue
	ALTER COLUMN attempts SET DEFAULT 0,
	ALTER COLUMN attempts SET NOT NULL;

ALTER TABLE user_notification_expired
	ALTER COLUMN attempts SET DEFAULT 0,
	ALTER COLUMN attempts SET NOT NULL;

ALTER TABLE user_project
	ALTER COLUMN pins TYPE jsonb;

ALTER TABLE user_profile
	ALTER COLUMN favorites TYPE jsonb;

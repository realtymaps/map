UPDATE user_project
set pins = '{}'
where pins is null;

UPDATE user_profile
set favorites = '{}'
where favorites is null;

ALTER TABLE user_project
	ALTER COLUMN pins SET DEFAULT '{}',
	ALTER COLUMN pins SET NOT NULL;

ALTER TABLE user_profile
	ALTER COLUMN favorites SET DEFAULT '{}',
	ALTER COLUMN favorites SET NOT NULL;

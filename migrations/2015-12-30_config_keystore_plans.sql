-- Elminate Basic Tier and simplify to just Standard, Premium, and Free
WITH basic_rows AS(
	SELECT id from auth_group
	where name = 'Basic Tier'
)
UPDATE auth_m2m_user_groups
SET
	group_id=(SELECT id from auth_group where name = 'Standard Tier')
FROM (select id from basic_rows) as subQuery
WHERE group_id = subQuery.id;


WITH basic_rows AS(
	SELECT id from auth_group
	where name = 'Basic Tier'
)
UPDATE auth_m2m_group_permissions
SET
	group_id=(SELECT id from auth_group where name = 'Standard Tier')
FROM (select id from basic_rows) as subQuery
WHERE group_id = subQuery.id;


DELETE FROM auth_group where name = 'Basic Tier';

--END Elminate Basic Tier and simplify to just Standard, Premium, and Free

INSERT INTO config_keystore (namespace, key, value) VALUES
	('plans', 'premium',  '{ "maxLogins": 2, "price": 50.00, "alias": "pro"}'),
	('plans', 'standard', '{ "maxLogins": 1, "price": 15.00, "alias": "basic"}'),
	('plans', 'free',     '{ "maxLogins": 1, "price": 0.00}');

DELETE FROM config_keystore where namespace = 'max logins';

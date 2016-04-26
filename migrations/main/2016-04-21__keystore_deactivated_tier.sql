insert into config_keystore (namespace, key, value) values ('plans', 'deactivated', '{"maxLogins": 0, "price": 0.00, "interval": "month", "group_id": 5}');

UPDATE config_keystore SET value = jsonb_set(value::jsonb, '{"group_id"}', '3') where key='standard';
UPDATE config_keystore SET value = jsonb_set(value::jsonb, '{"group_id"}', '4') where key='premium';
UPDATE config_keystore SET value = jsonb_set(value::jsonb, '{"group_id"}', '1') where key='free';

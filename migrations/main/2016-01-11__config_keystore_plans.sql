UPDATE config_keystore
	SET value='{ "maxLogins": 2, "price": 50.00, "alias": "pro", "interval":"month"}'
WHERE namespace = 'plans' and key = 'premium';

UPDATE config_keystore
	SET value='{ "maxLogins": 1, "price": 15.00, "alias": "basic", "interval":"month"}'
WHERE namespace = 'plans' and key = 'standard';

UPDATE config_keystore
	SET value='{ "maxLogins": 1, "price": 0.00, "interval":"month"}'
WHERE namespace = 'plans' and key = 'free';

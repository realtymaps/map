CREATE TABLE user_notification_expired (
	id serial,
	config_notification_id int NOT NULL,
	options json NOT NULL DEFAULT '{}'::json,
	rm_inserted_time timestamp(6) NOT NULL DEFAULT now_utc(),
	rm_modified_time timestamp(6) NOT NULL DEFAULT now_utc(),
	attempts int4,
	error text,
	status text,
	PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);

ALTER TABLE user_notification_expired
ADD CONSTRAINT user_notification_config_notification_id_fk
FOREIGN KEY (config_notification_id)
REFERENCES user_notification_config (id)
ON UPDATE CASCADE ON DELETE CASCADE NOT DEFERRABLE INITIALLY IMMEDIATE;

CREATE TABLE user_notification_methods (
  id serial,
  code_name varchar(20) NOT NULL,
  name text NOT NULL,
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);

INSERT into user_notification_methods (code_name, name) values
('emailVero', 'Email'),
('email', 'Email server hosted'),
('sms', 'Text Message');

ALTER TABLE user_notification_config add column method_id int4;


ALTER TABLE user_notification_config
ADD CONSTRAINT fk_user_notifcation_config_method_id
FOREIGN KEY (method_id)
REFERENCES user_notification_methods (id)
ON DELETE CASCADE NOT DEFERRABLE INITIALLY IMMEDIATE;


UPDATE user_notification_config as config
  set method_id=method.id
from user_notification_methods as method
where config.method = method.code_name;


ALTER TABLE user_notification_config alter column method_id SET NOT NULL;

ALTER TABLE user_notification_config drop column method;

-- fix config_handlers_event_map

ALTER TABLE config_handlers_event_map add column method_id int4;

ALTER TABLE config_handlers_event_map
ADD CONSTRAINT fk_config_handlers_event_map_method_id
FOREIGN KEY (method_id)
REFERENCES user_notification_methods (id)
ON DELETE CASCADE NOT DEFERRABLE INITIALLY IMMEDIATE;


UPDATE config_handlers_event_map as handle
  set method_id=method.id
from user_notification_methods as method
where handle.method = method.code_name;


ALTER TABLE config_handlers_event_map alter column method_id SET NOT NULL;

ALTER TABLE config_handlers_event_map drop column method;

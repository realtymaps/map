CREATE TABLE user_notification_frequencies (
  id serial,
  code_name varchar(20) NOT NULL,
  name text NOT NULL,
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);

INSERT into user_notification_frequencies (code_name, name) values
('onDemand', 'Immediate'),
('daily', 'Daily'),
('weekly', 'Weekly'),
('monthly', 'Monthly'),
('off', 'Off');

ALTER TABLE user_notification_config add column frequency_id int4;


ALTER TABLE user_notification_config
ADD CONSTRAINT fk_user_notifcation_config_frequency_id
FOREIGN KEY (frequency_id)
REFERENCES user_notification_frequencies (id)
ON DELETE CASCADE NOT DEFERRABLE INITIALLY IMMEDIATE;


UPDATE user_notification_config as config
  set frequency_id=frequency.id
from user_notification_frequencies as frequency
where config.frequency = frequency.code_name;


ALTER TABLE user_notification_config alter column frequency_id SET NOT NULL;

ALTER TABLE user_notification_config drop column frequency;

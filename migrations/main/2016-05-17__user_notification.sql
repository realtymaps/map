ALTER TABLE user_notification DROP CONSTRAINT user_notification_auth_user_id_fk;

ALTER TABLE user_notification ADD
  CONSTRAINT user_notification_config_notification_id_fk FOREIGN KEY ("config_notification_id")
  REFERENCES config_notification ("id") ON UPDATE CASCADE ON DELETE CASCADE;

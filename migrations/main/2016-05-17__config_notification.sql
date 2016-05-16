
CREATE INDEX config_notification_id_auth_user_id_method_type_frequency_idx
ON config_notification USING btree (id, auth_user_id, method, type, frequency);

CREATE INDEX config_notification_type_idx
ON config_notification USING btree (type);

CREATE INDEX  config_notification_method_type_frequency_idx
ON config_notification USING btree (method, type, frequency);

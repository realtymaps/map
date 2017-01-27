create table deletes_events_queue(
  event_id int,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  CONSTRAINT deletes_events_queue_auth_user_id_fk FOREIGN KEY (event_id) REFERENCES user_events_queue (id) ON DELETE CASCADE,
  PRIMARY KEY(event_id)
);


create table deletes_notification_queue(
  notification_id int,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  CONSTRAINT deletes_events_queue_auth_user_id_fk FOREIGN KEY (notification_id)
    REFERENCES user_notification_queue (id) ON DELETE CASCADE,
  PRIMARY KEY(notification_id)
);

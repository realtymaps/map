DROP TABLE IF EXISTS data_event_history;
CREATE TABLE data_event_history (
    auth_user_id int NOT NULL,
    event_type TEXT,
    ip_address INET,
    data_blob JSON,
    rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc()
);

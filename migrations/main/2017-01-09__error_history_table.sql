ALTER TABLE history_request_error ADD COLUMN referrer TEXT;
ALTER TABLE history_request_error ADD COLUMN route_info JSON;
ALTER TABLE history_request_error ADD COLUMN ua TEXT;
ALTER TABLE history_request_error ADD COLUMN ua_browser JSON;
ALTER TABLE history_request_error ADD COLUMN ua_engine JSON;
ALTER TABLE history_request_error ADD COLUMN ua_os JSON;
ALTER TABLE history_request_error ADD COLUMN ua_device JSON;
ALTER TABLE history_request_error ADD COLUMN ua_cpu JSON;

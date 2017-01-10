CREATE TABLE history_browser_error (
  reference TEXT,
  count INT,
  message TEXT NOT NULL,
  file TEXT,
  line TEXT,
  col TEXT,
  stack JSON,
  url TEXT NOT NULL,
  ip INET,
  referrer TEXT,
  userid INTEGER,
  email TEXT,
  ua TEXT,
  ua_browser JSON,
  ua_engine JSON,
  ua_os JSON,
  ua_device JSON,
  ua_cpu JSON,
  session JSON,
  handled BOOLEAN DEFAULT FALSE NOT NULL,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc()
);

CREATE INDEX ON history_browser_error (unexpected, rm_inserted_time);
CREATE INDEX ON history_browser_error (handled, rm_inserted_time);
CREATE INDEX ON history_browser_error (reference);

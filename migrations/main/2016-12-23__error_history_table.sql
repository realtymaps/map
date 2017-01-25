CREATE TABLE history_request_error (
  reference TEXT,
  type TEXT,
  details TEXT,
  quiet BOOLEAN NOT NULL,
  url TEXT NOT NULL,
  method TEXT NOT NULL,
  headers JSON NOT NULL,
  body JSON,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  userid INTEGER,
  session JSON,
  response_status INTEGER NOT NULL,
  unexpected BOOLEAN NOT NULL,
  handled BOOLEAN DEFAULT FALSE NOT NULL
);

CREATE INDEX ON history_request_error (unexpected, rm_inserted_time);
CREATE INDEX ON history_request_error (handled, rm_inserted_time);
CREATE INDEX ON history_request_error (reference);
CREATE INDEX ON history_request_error (type);
CREATE INDEX ON history_request_error (response_status);

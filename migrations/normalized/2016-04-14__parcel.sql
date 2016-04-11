ALTER TABLE parcel add column deleted text;
ALTER TABLE parcel add column change_history jsonb NOT NULL DEFAULT '[]'::jsonb;

CREATE INDEX  parcel_change_history_idx ON parcel USING gin (change_history);

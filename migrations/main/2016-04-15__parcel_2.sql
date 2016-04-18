ALTER TABLE parcel add column inserted text NOT NULL DEFAULT 'invalid'::text;
ALTER TABLE parcel add column updated text;

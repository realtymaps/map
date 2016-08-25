CREATE TABLE data_photo (
    rm_inserted_time timestamp without time zone DEFAULT now_utc() NOT NULL,
    rm_property_id text NOT NULL,
    photo_id text,
    photo_count integer,
    photos jsonb DEFAULT '{}'::jsonb NOT NULL,
    photo_last_mod_time timestamp without time zone,
    actual_photo_count integer DEFAULT 0 NOT NULL,
    cdn_photo text DEFAULT ''::text NOT NULL
);
